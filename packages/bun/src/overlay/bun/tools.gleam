//// This module is the effectful implementation of the tool calls available to overlay.
//// The state passed to each tool call is a cache of state that is reusable between tool calls.
//// Currently this state is only used for keeping access tokens for authenticated calls to API's
//// The state is currently a bun specific implementation however as it is scoped to tool calls it could be moved to overlay
//// Moving the full application state to overlay core is a bad idea, because we want to track different state when streaming
//// vs using The Elm Architecture in a Lustre web app.
//// 
//// The code execution tool is defined sans io using an effect type defined in this project.
//// The other tools could use the same effect logic, this is probably a good idea once we start applying policies for which files can be read.

import gleam/fetch
import gleam/io
import gleam/javascript/promise.{type Promise}
import gleam/result
import gleam/string
import gleam_community/ansi
import overlay/bun/config
import overlay/bun/gleam/fetchx
import overlay/bun/midas
import overlay/bun/tools/eval
import overlay/bun/tools/state.{type State, State}
import overlay/filepathx
import overlay/llm/tool
import overlay/tools
import overlay/tools/get
import overlay/tools/ls
import overlay/tools/read
import overlay/tools/search
import simplifile
import snag
import spotless
import spotless/oauth_2_1/token
import spotless/proof_key_for_code_exchange as pkce

pub fn execute(
  call: tool.FunctionCall,
  state: State,
) -> Promise(Result(#(tool.Return, _), String)) {
  let tool.FunctionCall(name, arguments) = call
  case tools.cast(name, arguments) {
    Ok(call) -> {
      io.println(ansi.bg_bright_green(tools.log_line(call)))
      case call {
        tools.Eval(code) -> do(eval.run(code, state))
        tools.Get(url) -> get(url, state)
        tools.Ls(path) -> ls(path, state)
        tools.Read(path) -> read(path, state)
        tools.Search(query) -> search(query, state)
        tools.Write(#(path, content)) -> write(path, content, state)
      }
    }
    Error(reason) ->
      promise.resolve(Error(tools.describe_failure(reason, name, arguments)))
  }
}

fn do(return) {
  let #(state, action) = return
  case action {
    eval.Done(Ok(text)) -> promise.resolve(Ok(#(tool.Return(text, []), state)))
    eval.Done(Error(reason)) -> promise.resolve(Error(reason))
    eval.Authorize(service:, resume:) -> {
      use return <- promise.await(
        midas.run(spotless.authenticate(service, [], "", 8080, pkce.S256)),
      )
      let return = case return {
        Ok(token.Response(access_token:, ..)) -> Ok(access_token)
        Error(reason) -> Error(snag.line_print(reason))
      }
      do(resume(return))
    }
    eval.Read(path:, resume:) -> {
      // relative resolved in lookup in eval
      // let State(config:) = state
      // let assert Ok(path) = filepathx.resolve_relative(config.root, path)
      io.println("reading lower: " <> path)
      do(resume(simplifile.read_bits(path)))
    }
    eval.Fetch(request:, resume:) -> {
      use result <- promise.await(fetchx.send_bits(request))
      do(resume(result))
    }
  }
}

fn get(url: String, state: a) -> Promise(Result(#(tool.Return, a), String)) {
  use #(request, resume) <- promise.try_sync(get.sans_io(url))
  use response <- promise.try_await(send(request))
  promise.resolve(Ok(#(resume(response), state)))
}

fn ls(path, state) {
  let State(config:) = state
  use path <- promise.try_sync(filepathx.resolve_relative(config.root, path))
  use content <- promise.try_sync(
    simplifile.read_directory(path)
    |> result.map_error(simplifile.describe_error),
  )
  promise.resolve(Ok(#(ls.resume(content), state)))
}

fn read(path, state) {
  let State(config:) = state
  use path <- promise.try_sync(filepathx.resolve_relative(config.root, path))
  use content <- promise.try_sync(
    simplifile.read_bits(path)
    |> result.map_error(simplifile.describe_error),
  )
  use value <- promise.try_sync(read.resume(path, content))
  promise.resolve(Ok(#(value, state)))
}

pub fn search(query, state) -> Promise(Result(_, String)) {
  use token <- promise.try_sync(config.get_env("OLLAMA_API_KEY"))
  let #(request, resume) = search.sans_io(token, query)
  use response <- promise.try_await(send(request))
  use value <- promise.try_sync(resume(response))
  promise.resolve(Ok(#(value, state)))
}

fn write(path, content, state) {
  let State(config:) = state
  use path <- promise.try_sync(filepathx.resolve_relative(config.root, path))
  use Nil <- promise.try_sync(
    simplifile.write(path, content)
    |> result.map_error(simplifile.describe_error),
  )
  let value = tool.Return("written", [])
  promise.resolve(Ok(#(value, state)))
}

fn send(request) {
  use return <- promise.await(fetch.send(request))
  use response <- promise.try_sync(return |> result.map_error(string.inspect))
  use return <- promise.await(fetch.read_text_body(response))
  promise.resolve(return |> result.map_error(string.inspect))
}
