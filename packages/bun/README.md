# Overlay Bun

A Cli implementation of the Overlay assistant.

## Installation

To build and install from source

```sh
./bin/compile
```

Copy to a directory on your $PATH. *This will probably require sudo.*
```sh
mv ./dist/overlay /usr/local/bin/overlay
```

To achieve all in one step use the install script.

```sh
./bin/install
```

## Development

```sh
gleam run . --read ../sibling --history
```

To run the tests.

```sh
gleam test  # Run the tests
```
