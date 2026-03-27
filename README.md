# Overlay

Overlay is an open LLM workspace assistant.

## Packages

The project is broken into the following packages.
- [LLM](./packages/llm) An API for LLM completion that unifies across different providers.
- [Overlay](./packages/overlay) The platform agnostic logic of the Overlay assistant.
- [Web](./packages/web) The web implementation of Overlay.
- [Bun](./packages/bun) The default Tui implementation of Overlay built on bun.js.

## Getting started

To get started with Overlay in your terminal follow the instructions in the bun package [README](./packages/bun/README.md)

### Setup skills

Overlay will look for a `skills` directory in the working directory and all parent directories.
Additional skills directories can be configured in `~/.config/overlay/config.json`.

For example, to add the overlay skills add the path to the skills directory of a copy of the overlay repo.
```json
{
  "skills":["~/Projects/crowdhailer/overlay/skills"]
}
```

## Contributing

To contribute to this repo requires `bun` and `gleam` to be installed.

## Credit

Created for [EYG](https://eyg.run/), a new integration focused programming language.