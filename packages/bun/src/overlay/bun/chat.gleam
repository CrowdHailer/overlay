import gleam/javascript/promise
import overlay/bun/agent
import overlay/bun/cli
import overlay/bun/tools/state
import overlay/llm/chat

pub fn start(config) {
  // Bare config is used by the llm to build full system prompt with tools.
  // State is used by tools to find the cwd.
  outer_loop(config, [], state.State(config:))
}

fn outer_loop(config, history, store) -> promise.Promise(Nil) {
  case cli.input(">>>", "send a message") {
    Ok("") -> promise.resolve(Nil)
    Ok(text) -> {
      let history = [chat.UserMessage(text, []), ..history]
      use result <- promise.await(agent.inner_loop(config, history, store))
      case result {
        Ok(#(config, history, store)) -> outer_loop(config, history, store)
        Error(_) -> promise.resolve(Nil)
      }
    }
    Error(Nil) -> promise.resolve(Nil)
  }
}
