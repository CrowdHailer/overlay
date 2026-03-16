import castor
import gleam/dynamic/decode
import oas/generator/utils
import overlay/llm/tool
import overlay/tools/eval
import overlay/tools/list
import overlay/tools/read
import overlay/tools/search

pub fn specs() {
  [
    eval.spec(),
    tool.Tool("fetch", "Get the content at the provided url", [
      castor.field("url", castor.string()),
    ]),
    list.spec(),
    read.spec(),
    search.spec(),
    tool.Tool("write", "write a file", [
      castor.field("path", castor.string()),
      castor.field("content", castor.string()),
    ]),
  ]
}

pub type Call {
  Eval(String)
  Fetch(String)
  Ls(String)
  Read(String)
  Search(String)
  Write(#(String, String))
}

pub fn log_line(call) {
  case call {
    Eval(_code) -> "Evaluating EYG code."
    Fetch(url) -> "Fetching url: " <> url
    Ls(path) -> "Listing file: " <> path
    Read(path) -> "Reading file: " <> path
    Search(query) -> "Searching web: " <> query
    Write(#(path, _)) -> "Writing file: " <> path
  }
}

pub type CastFailure {
  DecodeError(List(decode.DecodeError))
  UnknownTool
}

// let message = "Failed to call tool `" <> name <> "` it is not setup."
// io.println(ansi.bg_bright_red(message))
pub fn cast(name, arguments) {
  case name {
    "eval" -> eval.cast(arguments) |> to(Eval)
    "fetch" -> fetch_cast(arguments) |> to(Fetch)
    "list" -> list.cast(arguments) |> to(Ls)
    "read" -> read.cast(arguments) |> to(Read)
    "search" -> search.cast(arguments) |> to(Search)
    "write" -> write_cast(arguments) |> to(Write)
    _ -> Error(UnknownTool)
  }
}

fn to(result, call) {
  case result {
    Ok(arguments) -> Ok(call(arguments))
    Error(reason) -> Error(DecodeError(reason))
  }
}

fn fetch_cast(arguments) {
  let arguments = utils.fields_to_dynamic(arguments)
  let decoder = {
    decode.field("url", decode.string, decode.success)
  }
  decode.run(arguments, decoder)
}

fn write_cast(arguments) {
  let arguments = utils.fields_to_dynamic(arguments)
  let decoder = {
    use path <- decode.field("path", decode.string)
    use content <- decode.field("content", decode.string)
    decode.success(#(path, content))
  }
  decode.run(arguments, decoder)
}
