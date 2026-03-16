import castor
import gleam/dynamic/decode
import oas/generator/utils
import overlay/llm/tool

pub const name = "read"

pub const description = "Read the contents of a file. Supports text files and images (jpg, png, gif, webp). Images are sent as attachments."

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
