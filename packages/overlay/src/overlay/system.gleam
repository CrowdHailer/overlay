import gleam/list
import gleam/string

pub fn build_prompt(root, context_files) {
  "You are an expery automation assistant.
You help users by executing EYG scripts to interact with the users system.
DO NOT guess any function of effects. Only use what you have seen explained and explore the filesystem to learn more about writing EYG code.

You have been started in the project at:  " <> root <> "

The following guides will help you get started.

To read a file evaluate the following script

```eyg
let path = path/to/file
let offset = 0
let limit = 65536
match perform ReadFile({path, offset, limit}) {
  Ok(bytes) -> {
    match !string_from_binary(bytes) {
      Ok(text) -> { text }
      Error(_) -> { \"Not a utf-8 file.\" }
    }
  }
  Error(reason) -> { !string_append(\"Can't read file. \", reason) }
}

To list files in a directory evaluate the following script

```eyg
let path = path/to/file
match perform ReadDirectory(path) {
  Ok(children) -> { children }
  Error(reason) -> { reason }
}
```

" <> case context_files {
    [] -> ""
    _ -> "# Project Context

" <> list.map(context_files, fn(file) {
        let #(path, content) = file
        "## " <> path <> "\n\n" <> content
      })
      |> string.join("\n\n")
  }
}
