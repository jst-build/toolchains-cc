# Bundled Protobuf Toolchain Example

This is an example compiled with the bundled Protobuf toolchain built from
source.

The bundled toolchain is imported via this entry in the `repos.in.json` file:

```json
{
  "source": "git",
  "branch": "protobuf/v29.0",
  "url": "https://github.com/jst-build/toolchains-cc",
  "repos": [{"alias": "toolchain"}]
}
```

## Run the example

To build the toolchain and compile, install, and run the example:

```
jst install -o out
./out/bin/add_person address.db
./out/bin/list_people address.db
```

> [!NOTE]
> Example taken from the [Protobuf repository](https://github.com/protocolbuffers/protobuf/tree/v35.1/examples).

## Use the system toolchain

To switch to the system toolchain, change the branch in the `repos.in.json`,
regenerate `repo.json` by running `jst-lock`, and rebuild:

```
sed -i 's|protobuf/v[0-9\.]*|system|' repos.in.json
jst-lock
jst install -o out
```

> [!WARNING]
> Protobuf must be installed in the system for this to work.
