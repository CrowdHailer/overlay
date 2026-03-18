import gleam/dict
import gleam/int
import gleam/io
import overlay/bun/cli
import overlay/bun/config
import overlay/bun/skills

pub fn main() -> Nil {
  use config <- try(config.load())
  io.println("started overlay in dir: " <> config.root)
  let skills = skills.read_all(config.root)
  io.println("discovered " <> int.to_string(dict.size(skills)) <> " skills")
  outer_loop()
}

fn outer_loop() {
  case cli.input(">>>", "send a message") {
    Ok("") -> Nil
    Ok(_text) -> {
      io.println("thanks for your message.")
      outer_loop()
    }
    Error(Nil) -> Nil
  }
}

fn try(result, then) {
  case result {
    Ok(value) -> then(value)
    Error(reason) -> {
      io.println(reason)
    }
  }
}
