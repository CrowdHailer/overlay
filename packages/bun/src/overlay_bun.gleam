import gleam/dict
import gleam/int
import gleam/io
import gleam/javascript/promise
import overlay/bun/chat
import overlay/bun/config
import overlay/bun/skills

pub fn main() -> promise.Promise(Nil) {
  use config <- try(config.load())
  io.println("started overlay in dir: " <> config.root)
  let skills = skills.read_all(config.root)
  io.println("discovered " <> int.to_string(dict.size(skills)) <> " skills")
  chat.start(config)
}

fn try(result, then) {
  case result {
    Ok(value) -> then(value)
    Error(reason) -> {
      promise.resolve(io.println(reason))
    }
  }
}
