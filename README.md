# Protobuf toolchain for the `jst` build system

A toolchain definition that layers a bundled, from-source build of
Protocol Buffers (`protoc`, `libprotobuf`). All other compilers and tools will
be taken from the system by default (see [Repository Remapping](#repository-remapping) below).

## How to use this Repository

To import `toolchain` to your repository, add the following code to the *imports
section* of your `repos.in.json` and run `jst-lock` to generate the final
repository lock-file

```jsonc
"imports": [
  {
    "source": "git",
    "branch": "protobuf/v35.1",
    "url": "https://github.com/jst-build/toolchains-cc",
    "repos": [{"alias": "toolchain"}]
  },
  // ...
],
```

## General Configuration

This toolchain uses the [system toolchain's own configuration](https://github.com/jst-build/toolchains-cc/blob/system/README.md#general-configuration)
(`ARCH`, `TOOLCHAIN_CONFIG`, ...) to compile C/C++ code, and introduces no
additional configuration variables of its own.

## Repository Remapping

This toolchain repository can be imported with two remappings:

- `base_toolchain`: The base toolchain with compilers and tools, which are used
  for building Protobuf and are also forwarded to the consumers of this
  toolchain. (default: [system
  toolchain](https://github.com/jst-build/toolchains-cc/blob/system/README.md))
- `protobuf`: The bundled Protobuf repository, which must provide the top-level
  targets `INSTALL` and `libprotobuf`. It is recommended to build Protobuf with the same base toolchain.

Remappings may happen independently of each other.

**Example:** Import with remapping base toolchain and Protobuf:

```jsonc
"imports": [
  { // ...
    "repos": [{
      "alias": "toolchain",
      "map": {
        "base_toolchain": "my-custom-toolchain",
        "protobuf": "my-protobuf-built-with-my-custom-toolchain"
      }
    }]
  }
  // ...
]
```