import gleam/fetch
import gleam/io
import gleam/javascript/promise.{type Promise}
import gleam/result
import gleam/string
import gleam_community/ansi
import overlay/bun/config
import overlay/llm/tool
import overlay/tools
import overlay/tools/get
import overlay/tools/ls
import overlay/tools/read
import overlay/tools/search
import simplifile

pub fn execute(
  call: tool.FunctionCall,
  store,
) -> Promise(Result(#(tool.Return, _), String)) {
  let tool.FunctionCall(name, arguments) = call
  case tools.cast(name, arguments) {
    Ok(call) -> {
      io.println(ansi.bg_bright_green(tools.log_line(call)))
      case call {
        tools.Eval(_code) -> {
          let message = "Failed to call tool `" <> name <> "` it is not setup."
          promise.resolve(Error(message))
        }
        tools.Get(url) -> get(url, store)
        tools.Ls(path) -> ls(path, store)
        tools.Read(path) -> read(path, store)
        tools.Search(query) -> search(query, store)
        tools.Write(#(path, content)) -> write(path, content, store)
      }
    }
    Error(reason) ->
      promise.resolve(Error(tools.describe_failure(reason, name, arguments)))
  }
}

fn get(url, store) {
  use #(request, resume) <- promise.try_sync(get.sans_io(url))
  use response <- promise.try_await(send(request))
  promise.resolve(Ok(#(resume(response), store)))
}

fn ls(path, store) {
  use content <- promise.try_sync(
    simplifile.read_directory(path)
    |> result.map_error(simplifile.describe_error),
  )
  promise.resolve(Ok(#(ls.resume(content), store)))
}

fn read(path, store) {
  use content <- promise.try_sync(
    simplifile.read_bits(path)
    |> result.map_error(simplifile.describe_error),
  )
  use value <- promise.try_sync(read.resume(path, content))
  promise.resolve(Ok(#(value, store)))
}

pub fn search(query, store) -> Promise(Result(_, String)) {
  use token <- promise.try_sync(config.get_env("OLLAMA_API_KEY"))
  let #(request, resume) = search.sans_io(token, query)
  use response <- promise.try_await(send(request))
  use value <- promise.try_sync(resume(response))
  promise.resolve(Ok(#(value, store)))
}

fn write(path, content, store) {
  use Nil <- promise.try_sync(
    simplifile.write(path, content)
    |> result.map_error(simplifile.describe_error),
  )
  let value = tool.Return("written", [])
  promise.resolve(Ok(#(value, store)))
}

fn send(request) {
  use return <- promise.await(fetch.send(request))
  use response <- promise.try_sync(return |> result.map_error(string.inspect))
  use return <- promise.await(fetch.read_text_body(response))
  promise.resolve(return |> result.map_error(string.inspect))
}
