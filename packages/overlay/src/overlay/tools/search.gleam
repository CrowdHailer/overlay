import castor
import gleam/dynamic/decode
import oas/generator/utils
import overlay/llm/tool

pub const name = "search"

pub const description = "Search the web for the latest information to reduce hallucinations and improve accuracy."

pub fn parameters() {
  [castor.field("query", castor.string())]
}

pub fn spec() {
  tool.Tool(name, description, parameters())
}

pub fn cast(arguments) {
  let arguments = utils.fields_to_dynamic(arguments)
  let decoder = {
    decode.field("query", decode.string, decode.success)
  }
  decode.run(arguments, decoder)
}
