import castor
import gleam/dynamic/decode
import oas/generator/utils
import overlay/llm/tool

pub const name = "list"

pub const description = "List the contents of a directory"

pub fn parameters() {
  [castor.field("path", castor.string())]
}

pub fn spec() {
  tool.Tool(name, description, parameters())
}

pub fn cast(arguments) {
  let arguments = utils.fields_to_dynamic(arguments)
  let decoder = {
    decode.field("path", decode.string, decode.success)
  }
  decode.run(arguments, decoder)
}
