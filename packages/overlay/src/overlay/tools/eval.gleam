import castor
import eyg/interpreter/break
import eyg/ir/tree
import eyg/parser
import gleam/dynamic/decode
import gleam/http/request
import gleam/result
import oas/generator/utils
import ogre/operation
import overlay/llm/tool
import overlay/runner
import touch_grass/decode_json
import touch_grass/fetch
import touch_grass/http
import touch_grass/read

pub const name = "eval"

pub const description = "Run an EYG script, always read the write-eyg skill before evaluating any code."

pub fn parameters() {
  [castor.field("code", castor.string())]
}

pub fn spec() {
  tool.Tool(name, description, parameters())
}

pub fn cast(arguments) {
  let arguments = utils.fields_to_dynamic(arguments)
  let decoder = {
    decode.field("code", decode.string, decode.success)
  }
  decode.run(arguments, decoder)
}

pub fn sans_io(code: String) {
  use source <- result.map(parser.all_from_string(code))
  let source = tree.clear_annotation(source)
  runner.expression(source, parse_effect)
}

/// The effects defined here mean that the effects available to scripts in overlay assitants are always the same.
/// I have made the assumption that overlay assistants will all be set up to work in a similar workspace.
/// If this assumption is false, the sans_io function will accept a parse_effect function from the caller.
pub type Effect {
  DirectFetch(service: String, operation: operation.Operation(BitArray))
  Fetch(request: request.Request(BitArray))
  Read(path: String)
}

fn parse_effect(label, lift) {
  case label {
    "DecodeJSON" -> {
      use input <- result.map(decode_json.decode(lift))
      runner.Reply(decode_json.sync(input))
    }
    "DNSimple" -> direct_fetch("dnsimple", lift)
    "Fetch" -> {
      use request <- result.map(fetch.decode(lift))
      runner.External(Fetch(request:))
    }
    "Read" -> {
      use path <- result.map(read.decode(lift))
      runner.External(Read(path:))
    }
    _ -> Error(break.UnhandledEffect(label, lift))
  }
}

fn direct_fetch(service, lift) {
  use operation <- result.map(http.operation_to_gleam(lift))
  runner.External(DirectFetch(service:, operation:))
}
