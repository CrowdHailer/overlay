import castor
import gleam/dynamic/decode
import oas/generator/utils
import overlay/llm/tool

pub const name = "eval"

pub const description = "Run an EYG script"

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
