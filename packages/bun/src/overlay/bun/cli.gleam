import gleam/io
import gleam/string
import gleam_community/ansi
import input

pub fn input(prompt, placeholder) {
  let prompt = ansi.bold(ansi.yellow(prompt))
  io.print(prompt)
  io.print(" ")
  io.print(ansi.dim(placeholder))
  io.print("\r")
  io.print(prompt)
  io.print(" ")
  case input.input("") {
    Ok(line) -> Ok(string.trim_end(line))
    Error(reason) -> Error(reason)
  }
}
