import gleam/dict
import gleam/int
import gleam/io
import gleam/javascript/promise
import gleam/list
import overlay/bun/chat
import overlay/bun/config
import overlay/bun/context
import overlay/bun/ralph
import overlay/bun/skills
import overlay/config.{Chat, Config, Ralph} as _
import simplifile

pub fn main() -> promise.Promise(Nil) {
  let assert Ok(cwd) = simplifile.current_directory()
  let context_files = context.read_all(cwd)
  io.println(
    "discovered "
    <> int.to_string(list.length(context_files))
    <> " context files",
  )
  use config <- try(config.load(context_files))
  io.println("started overlay in dir: " <> config.root)
  let skills = skills.read_all(config.root)
  io.println("discovered " <> int.to_string(dict.size(skills)) <> " skills")
  let config = Config(..config, skills:)
  case config.mode {
    Chat -> chat.start(config)
    Ralph -> ralph.start(config)
  }
}

fn try(result, then) {
  case result {
    Ok(value) -> then(value)
    Error(reason) -> {
      promise.resolve(io.println(reason))
    }
  }
}
