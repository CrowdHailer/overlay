import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/json
import oas/generator/utils
import overlay/tools/eval
import overlay/tools/search

pub fn specs() {
  [
    eval.spec(),
    search.spec(),
  ]
}

pub type Call {
  Eval(String)
  Search(String)
}

pub fn log_line(call) {
  case call {
    Eval(_code) -> "Evaluating EYG code."
    Search(query) -> "Searching web: " <> query
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
    "search" -> search.cast(arguments) |> to(Search)
    _ -> Error(UnknownTool)
  }
}

fn to(result, call) {
  case result {
    Ok(arguments) -> Ok(call(arguments))
    Error(reason) -> Error(DecodeError(reason))
  }
}
