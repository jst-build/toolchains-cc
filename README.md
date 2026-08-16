# Prebuilt Clang toolchain for the `jst` build system

A toolchain definition using prebuilt Clang for building.

## How to use this Repository

To import `toolchain` to your repository, add the following code to the *imports
section* of your `repos.in.json` and run `jst-lock` to generate the final
repository lock-file

```jsonc
"imports": [
  {
    "source": "git",
    "branch": "clang-amd64-gnu/v18.1.8",
    "url": "https://github.com/jst-build/toolchains-cc",
    "repos": [{"alias": "toolchain"}]
  },
  // ...
],
```

## General Configuration

In addition to the [system toolchain configuration](https://github.com/jst-build/toolchains-cc/blob/system/README.md#general-configuration),
the prebuilt Clang toolchain supports the following configuration variables:

|Variable|Description|Default Value|
|-|-|-:|
| `TOOLCHAIN_CONFIG["USE_LIBCXX"]` | Use LLVM's libc++ | `false` |
| `TOOLCHAIN_CONFIG["STATIC_RUNLIBS"]` | Link runtime libraries statically | `false` |

**Example:** Compiling using LLVM's libc++ and linking all runtime libraries
statically:

``` json
{
  "TOOLCHAIN_CONFIG": {
    "USE_LIBCXX": true,
    "STATIC_RUNLIBS": true
  }
}
```
