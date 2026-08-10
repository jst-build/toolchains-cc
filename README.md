# gRPC toolchain for the `jst` build system

A toolchain definition that layers bundled, from-source builds of gRPC and
Protocol Buffers (`grpc_cpp_plugin`, `libgrpc++`, `protoc`, `libprotobuf`).
All other compilers and tools will be taken from the system by default (see
[Repository Remapping](#repository-remapping) below).

## How to use this Repository

To import `toolchain` to your repository, add the following code to the *imports
section* of your `repos.in.json` and run `jst-lock` to generate the final
repository lock-file

```jsonc
"imports": [
  {
    "source": "git",
    "branch": "grpc/v1.83.0",
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

This toolchain repository can be imported with four remappings:

- `base_toolchain`: The base toolchain with compilers and tools, which are used
  for building Protobuf and gRPC but is also forwarded to the consumers of this
  toolchain. (default: [system
  toolchain](https://github.com/jst-build/toolchains-cc/blob/system/README.md))
- `protobuf`: The bundled Protobuf repository, which must provide the top-level
  targets `INSTALL` and `libprotobuf`. It is recommended to build Protobuf with
  the same base toolchain.
- `grpc`: The bundled gRPC repository, which must provide the top-level
  targets `grpc_cpp_plugin` and `libgrpc++`. It is recommended to build gRPC
  with the same Protobuf mapping and base toolchain.

> [!WARNING]
> Remappings may happen independently. However, it is recommended to always
> remap Protobuf *and* gRPC together (not only one of them), as not all their
> versions are compatible with each other.

**Example:** Import with remapping the base toolchain (also used to build
gRPC and Protobuf):

```jsonc
"imports": [
  { // ...
    "repos": [{
      "alias": "toolchain",
      "map": {
        "base_toolchain": "my-custom-toolchain"
      }
    }]
  }
  // ...
]
```

**Example:** Import with remapping the base toolchain, Protobuf, and gRPC:

```jsonc
"imports": [
  { // ...
    "repos": [{
      "alias": "toolchain",
      "map": {
        "base_toolchain": "my-custom-toolchain",
        "protobuf": "my-protobuf-built-with-my-custom-toolchain",
        "grpc": "my-grpc-built-with-my-protobuf-and-my-custom-toolchain"
      }
    }]
  }
  // ...
]
```
