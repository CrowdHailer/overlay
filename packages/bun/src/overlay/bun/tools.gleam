//// This module is the effectful implementation of the tool calls available to overlay.
//// The state passed to each tool call is a cache of state that is reusable between tool calls.
//// Currently this state is only used for keeping access tokens for authenticated calls to API's
//// The state is currently a bun specific implementation however as it is scoped to tool calls it could be moved to overlay
//// Moving the full application state to overlay core is a bad idea, because we want to track different state when streaming
//// vs using The Elm Architecture in a Lustre web app.
//// 
//// The code execution tool is defined sans io using an effect type defined in this project.
//// The other tools could use the same effect logic, this is probably a good idea once we start applying policies for which files can be read.

import eyg/cli/internal/execute
import eyg/cli/internal/source
import eyg/interpreter/simple_debug
import eyg/parser/parser
import gleam/fetch
import gleam/io
import gleam/javascript/promise.{type Promise}
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam_community/ansi
import overlay/bun/config as bun_config
import overlay/bun/tools/state.{type State}
import overlay/config
import overlay/llm/tool
import overlay/tools
import overlay/tools/search

pub fn execute(
  call: tool.FunctionCall,
  state: State,
) -> Promise(Result(#(tool.Return, _), String)) {
  let tool.FunctionCall(name, arguments) = call
  case tools.cast(name, arguments) {
    Ok(call) -> {
      io.println(ansi.bg_bright_green(tools.log_line(call)))
      case call {
        tools.Eval(code) -> {
          use exp <- promise.try_sync(
            source.block_expression(code)
            |> result.map_error(parser.describe_reason),
          )

          let config.Config(root:, execute_config:, ..) = state.config
          use result <- promise.map(execute.block(exp, [], root, execute_config))
          case result {
            // current state is not used by the CLI implementation, this will need to change.
            Ok(#(Some(value), _)) ->
              Ok(#(tool.Return(simple_debug.inspect(value), []), state))
            Ok(#(None, _)) -> Ok(#(tool.Return("", []), state))
            Error(reason) -> Error(simple_debug.describe(reason))
          }
        }
        tools.Search(query) -> search(query, state)
      }
    }
    Error(reason) ->
      promise.resolve(Error(tools.describe_failure(reason, name, arguments)))
  }
}

pub fn search(query, state) -> Promise(Result(_, String)) {
  use token <- promise.try_sync(bun_config.get_env("OLLAMA_API_KEY"))
  let #(request, resume) = search.sans_io(token, query)
  use response <- promise.try_await(send(request))
  use value <- promise.try_sync(resume(response))
  promise.resolve(Ok(#(value, state)))
}

fn send(request) {
  use return <- promise.await(fetch.send(request))
  use response <- promise.try_sync(return |> result.map_error(string.inspect))
  use return <- promise.await(fetch.read_text_body(response))
  promise.resolve(return |> result.map_error(string.inspect))
}
