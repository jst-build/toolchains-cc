# Bundled gRPC Toolchain Example

This is an example compiled with the bundled gRPC and Protobuf toolchains built
from source.

The bundled toolchain is imported via this entry in the `repos.in.json` file:

```json
{
  "source": "git",
  "branch": "grpc/v1.70.2",
  "url": "https://github.com/jst-build/toolchains-cc",
  "repos": [{"alias": "toolchain"}]
}
```

## Run the example

To build the toolchain and compile, install, and run the example:

```
jst install -o out
./out/bin/route_guide_server &
./out/bin/route_guide_client
kill %1
```

> [!NOTE]
> Example taken from the [gRPC repository](https://github.com/grpc/grpc/tree/v1.82.0/examples/cpp/route_guide)
> (with slight modifications to remove the Abseil dependency via `HAVE_ABSL`).

## Use the system toolchain

To switch to the system toolchain, change the branch in the `repos.in.json`,
regenerate `repo.json` by running `jst-lock`, and rebuild:

```
sed -i 's|grpc/v[0-9\.]*|system|' repos.in.json
jst-lock
jst install -o out
```

> [!WARNING]
> gRPC and Protobuf must be installed in the system for this to work.