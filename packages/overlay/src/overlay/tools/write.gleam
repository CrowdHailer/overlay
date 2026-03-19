import castor
import gleam/dynamic/decode
import oas/generator/utils
import overlay/llm/tool

pub const name = "write"

pub const description = "write a file"

pub fn parameters() {
  [
    castor.field("path", castor.string()),
    castor.field("content", castor.string()),
  ]
}

pub fn spec() {
  tool.Tool(name, description, parameters())
}

pub fn cast(arguments) {
  let arguments = utils.fields_to_dynamic(arguments)
  let decoder = {
    use path <- decode.field("path", decode.string)
    use content <- decode.field("content", decode.string)
    decode.success(#(path, content))
  }
  decode.run(arguments, decoder)
}
