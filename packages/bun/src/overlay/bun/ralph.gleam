import gleam/javascript/promise
import overlay/bun/agent
import overlay/bun/cli
import overlay/bun/tools/state
import overlay/llm/chat

pub fn start(config) {
  case cli.input("ralph>", "what's the task") {
    Ok("") -> promise.resolve(Nil)
    Ok(task) -> outer_loop(config, task, state.State(config:))
    Error(Nil) -> promise.resolve(Nil)
  }
}

fn outer_loop(config, task, store) -> promise.Promise(Nil) {
  let history = [chat.UserMessage(task, [])]
  use result <- promise.await(agent.inner_loop(config, history, store))
  case result {
    Ok(#(config, _history, store)) -> outer_loop(config, task, store)
    Error(_) -> promise.resolve(Nil)
  }
}
