import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/json
import oas/generator/utils
import overlay/tools/eval
import overlay/tools/get
import overlay/tools/ls
import overlay/tools/read
import overlay/tools/search
import overlay/tools/write

pub fn specs() {
  [
    eval.spec(),
    get.spec(),
    ls.spec(),
    read.spec(),
    search.spec(),
    write.spec(),
  ]
}

pub type Call {
  Eval(String)
  Get(String)
  Ls(String)
  Read(String)
  Search(String)
  Write(#(String, String))
}

pub fn log_line(call) {
  case call {
    Eval(_code) -> "Evaluating EYG code."
    Get(url) -> "Visiting url: " <> url
    Ls(path) -> "Listing file: " <> path
    Read(path) -> "Reading file: " <> path
    Search(query) -> "Searching web: " <> query
    Write(#(path, _)) -> "Writing file: " <> path
  }
}

pub type CastFailure {
  DecodeError(errors: List(decode.DecodeError))
  UnknownTool
}

pub fn describe_failure(
  failure: CastFailure,
  name: String,
  arguments: Dict(String, utils.Any),
) -> String {
  case failure {
    DecodeError(errors: _) -> {
      "Bad arguments for tool "
      <> name
      <> " arguments: "
      <> json.to_string(utils.any_to_json(utils.Object(arguments)))
    }
    UnknownTool -> {
      let message = "Failed to call tool `" <> name <> "` it is not setup."
      message
    }
  }
}

pub fn cast(
  name: String,
  arguments: Dict(String, utils.Any),
) -> Result(Call, CastFailure) {
  case name {
    "eval" -> eval.cast(arguments) |> to(Eval)
    "get" -> get.cast(arguments) |> to(Get)
    "list" -> ls.cast(arguments) |> to(Ls)
    "read" -> read.cast(arguments) |> to(Read)
    "search" -> search.cast(arguments) |> to(Search)
    "write" -> write.cast(arguments) |> to(Write)
    _ -> Error(UnknownTool)
  }
}

fn to(result, call) {
  case result {
    Ok(arguments) -> Ok(call(arguments))
    Error(reason) -> Error(DecodeError(reason))
  }
}
