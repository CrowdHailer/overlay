import gleam/io
import gleam/javascript/promise
import gleam_community/ansi
import overlay/bun/cli
import overlay/bun/llm
import overlay/bun/tools
import overlay/bun/tools/state
import overlay/llm/chat
import overlay/llm/tool

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
      inner_loop(config, history, store)
    }
    Error(Nil) -> promise.resolve(Nil)
  }
}

fn inner_loop(config, history, store) -> promise.Promise(_) {
  use return <- promise.await(llm.stream(config, history))
  io.println("")
  case return {
    Ok(completion) -> {
      let history = [chat.from_completion(completion), ..history]
      case completion.tool_calls {
        [] -> outer_loop(config, history, store)
        calls -> {
          use #(history, store) <- promise.await(sequential_calls(
            calls,
            history,
            store,
          ))
          inner_loop(config, history, store)
        }
      }
    }
    Error(reason) -> {
      io.println(reason)
      promise.resolve(Nil)
    }
  }
}

fn sequential_calls(calls, history, store) {
  case calls {
    [] -> promise.resolve(#(history, store))
    [call, ..rest] -> {
      let tool.Call(id:, function:) = call

      use result <- promise.await(tools.execute(function, store))
      let result = case result {
        Error(message) -> {
          io.println(ansi.bg_bright_red(message))
          Error(message)
        }
        Ok(#(value, _)) -> Ok(value)
      }
      let result = llm.result_to_message(id, result)
      let history = [result, ..history]

      sequential_calls(rest, history, store)
    }
  }
}
