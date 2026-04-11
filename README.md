# Overlay

Overlay is an open LLM workspace assistant.
It uses [EYG](https://eyg.run) for sandboxed scripting.

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
## Design Goals

The primary goal of Overlay is to safely generate and run scripts to solve problems in a context efficient manner.

### Super shell

Overlay is a superset of the [EYG shell](https://github.com/CrowdHailer/eyg-lang/tree/main/packages/gleam_cli).
In an EYG shell a human views guides, fetches packages and writes code.
In Overlay a human guides an LLM to do all the shell tasks and no more.

### Why EYG

EYG is a strong choice for LLM code as side effects can be inferred without running the program.
It is also strongly sandboxed, managed effects are the only way to access the underlying system.
All EYG expressions can be referenced by hash, providing a token efficient way to add dependencies.

### A full operating system

EYG modules can be installed from the EYG hub.

Agent skills and EYG guides are the same thing; they are instructions on how to accomplish certain tasks.
EYG guides refer to modules and this can be fetched by agents or humans

The file system is made available through separate tools because relative references in EYG make an assumption of a heirachical file system.

A full operation system would have UI. This comes later.
The EYG shell or Overlay can make effects available to listen to mouse events or write to the screen.
Mouse listen x/y that ends up on the screen
Effects are syscalls, packages that call them are drivers.

OS will provide authetication and users.
Overlay assumes a distributed auth and messaging layer, provided by [unteathered](https://github.com/CrowdHailer/eyg-lang/tree/main/packages/untethered) but not yet tightly integrated.

## Contributing

To contribute to this repo requires `bun` and `gleam` to be installed.

## Credit

Created for [EYG](https://eyg.run/), a new integration focused programming language.