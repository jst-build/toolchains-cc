#!/usr/bin/env bash
#
# Multi-branch operations across the import branches on 'origin' (every
# branch except master/main), each checked out as its own git worktree at a
# path matching the branch name (e.g. branch "grpc/v1.70.2" -> worktree
# directory "grpc/v1.70.2"). Similar in spirit to Android's "repo" tool.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

usage() {
  cat <<'EOF'
Usage: branch.sh <subcommand> [args]

Subcommands:
  init [pattern]          Add a worktree for every origin branch that doesn't
                          already have one (optionally filtered by a grep -E
                          pattern against the branch name).
  list [pattern]          List origin branches with their worktree path (if any)
                          and sync status vs origin.
  exec [pattern] <cmd>    Run <cmd> (a single shell command string) in every
                          matching branch that already has a worktree checked
                          out.
  gen-readme              Regenerate README.md with a link to every origin
                          branch's own README.md on GitHub.
EOF
}

if [ -t 1 ]; then
  COLOR_GREEN=$'\033[32m'
  COLOR_BLUE=$'\033[34m'
  COLOR_YELLOW=$'\033[33m'
  COLOR_RED=$'\033[31m'
  COLOR_RESET=$'\033[0m'
else
  COLOR_GREEN=""
  COLOR_BLUE=""
  COLOR_YELLOW=""
  COLOR_RED=""
  COLOR_RESET=""
fi

# origin_branches [pattern] - origin branch names, minus HEAD/master/main,
# optionally filtered with `grep -E` against pattern.
origin_branches() {
  local pattern="${1:-}"
  local names
  names=$(git branch --all | sed -n 's|^  remotes/origin/||p' | awk '{print $1}' \
    | grep -vE '^(HEAD|master|main)$')
  if [ -n "$pattern" ]; then
    grep -E -- "$pattern" <<< "$names"
  else
    printf '%s\n' "$names"
  fi
}

# worktree_map - one "branch<TAB>path" line per existing worktree, path
# relative to the repo root.
worktree_map() {
  git worktree list --porcelain | awk -v root="$PWD/" '
    /^worktree / {
      path = substr($0, 10)
      sub("^" root, "", path)
    }
    /^branch refs\/heads\// { branch = substr($0, 19); print branch "\t" path }
  '
}

# path_for_branch <branch> <worktree_map> - worktree path for branch, or "".
path_for_branch() {
  awk -F'\t' -v b="$1" '$1 == b { print $2; found = 1 } END { if (!found) exit 1 }' <<< "$2" || true
}

cmd_init() {
  local pattern="${1:-}"
  git fetch --all --prune

  local wt_map
  wt_map=$(worktree_map)

  local branch path count=0
  while IFS= read -r branch <&3; do
    [ -n "$branch" ] || continue
    path=$(path_for_branch "$branch" "$wt_map")
    if [ -n "$path" ]; then
      echo "== $branch (already checked out at $path) =="
      continue
    fi
    echo "== $branch =="
    if git show-ref --verify --quiet "refs/heads/$branch"; then
      git worktree add "$branch" "$branch"
    else
      git worktree add --track -b "$branch" "$branch" "origin/$branch"
    fi
    count=$((count + 1))
  done 3< <(origin_branches "$pattern")

  echo "Added $count worktree(s)."
}

cmd_list() {
  local pattern="${1:-}"
  local wt_map
  wt_map=$(worktree_map)

  local branch path status color counts behind ahead
  while IFS= read -r branch <&3; do
    [ -n "$branch" ] || continue
    path=$(path_for_branch "$branch" "$wt_map")
    if [ -z "$path" ]; then
      printf '%-14s %s\n' "not checked out" "$branch"
      continue
    fi
    if ! git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
      status="origin missing"
      color="$COLOR_RED"
    elif [ -n "$(git -C "$path" status --porcelain)" ]; then
      status="uncommitted"
      color="$COLOR_BLUE"
    else
      counts=$(git rev-list --left-right --count "origin/$branch...$branch")
      behind=$(cut -f1 <<< "$counts")
      ahead=$(cut -f2 <<< "$counts")
      if [ "$ahead" = 0 ] && [ "$behind" = 0 ]; then
        status="up-to-date"
        color="$COLOR_GREEN"
      elif [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
        status="diverged"
        color="$COLOR_RED"
      elif [ "$ahead" -gt 0 ]; then
        status="ahead $ahead"
        color="$COLOR_YELLOW"
      else
        status="behind $behind"
        color="$COLOR_YELLOW"
      fi
    fi
    printf '%s%-14s%s %s\n' "$color" "$status" "$COLOR_RESET" "$branch"
  done 3< <(origin_branches "$pattern")
}

cmd_exec() {
  local pattern="" cmd
  case $# in
    1) cmd="$1" ;;
    2) pattern="$1"; cmd="$2" ;;
    *) echo "exec: usage: exec [pattern] <cmd>" >&2; exit 1 ;;
  esac

  local wt_map
  wt_map=$(worktree_map)

  local branch path rc=0
  local -a skipped=()
  while IFS= read -r branch <&3; do
    [ -n "$branch" ] || continue
    path=$(path_for_branch "$branch" "$wt_map")
    if [ -z "$path" ]; then
      skipped+=("$branch")
      continue
    fi
    echo "== $branch =="
    ( cd "$path" && bash -c "$cmd" ) || { echo "!! $branch failed (exit $?)" >&2; rc=1; }
  done 3< <(origin_branches "$pattern")

  if [ ${#skipped[@]} -gt 0 ]; then
    echo "Warning: skipped (no worktree): ${skipped[*]}" >&2
  fi
  exit "$rc"
}

# Assign a sort rank per the desired category order:
# system, gcc*, clang*, protobuf*, grpc*, then anything else.
rank() {
  case "$1" in
    system)      echo 0 ;;
    gcc*)        echo 1 ;;
    clang*)      echo 2 ;;
    protobuf*)   echo 3 ;;
    grpc*)       echo 4 ;;
    *)           echo 5 ;;
  esac
}

# gen-readme regenerates README.md with a list of import branches, linking
# each to its own README.md on GitHub. Always covers every origin branch
# (no pattern filter) so the README never ends up partially regenerated.
cmd_gen_readme() {
  local repo_url="https://github.com/jst-build/toolchains-cc"
  local readme="README.md"
  git fetch --all --prune

  # Branches are namespaced per toolchain, e.g. "clang-amd64-gnu/v18.1.8",
  # "protobuf/v29.0". Within each toolchain group put the versions in
  # alphanumerical order; groups themselves are ordered by predefined rank.
  local ordered b lib variant rank
  ordered=$(
    while IFS= read -r b <&3; do
      [ -n "$b" ] || continue
      lib=${b%/*}
      variant=${b##*/}
      rank=1
      [ "$variant" = "system" ] && rank=0
      printf '%s\t%s\n' "$(rank "$b")" "$b"
    done 3< <(origin_branches) | sort -k1,1n -k2,2 | cut -f2-
  )

  {
    echo "# C/C++ Toolchains for the \`jst\` build system"
    echo
    cat <<'EOF'
Each toolchain lives on its own branch, listed below. Follow a link for details
about its setup and usage.
EOF
    echo
    while IFS= read -r b; do
      [ -n "$b" ] || continue
      echo "- [\`$b\`]($repo_url/tree/$b)"
    done <<< "$ordered"
    echo
    cat <<'EOF'
For more details on how to use those toolchains, see

- [Protobuf example](./examples/protobuf/)
- [gRPC example](./examples/grpc/)
EOF
  } > "$readme"

  echo "Wrote $readme with $(grep -c . <<< "$ordered") branch(es)."
}

subcommand="${1:-}"
[ $# -gt 0 ] && shift || true

case "$subcommand" in
  init) cmd_init "$@" ;;
  list) cmd_list "$@" ;;
  exec) cmd_exec "$@" ;;
  gen-readme) cmd_gen_readme "$@" ;;
  *) usage; exit 1 ;;
esac
