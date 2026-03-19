import castor
import filepath
import gleam/bit_array
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

pub fn resume(path, content) {
  case filepath.extension(path) {
    Ok("jpg") | Ok("png") | Ok("git") | Ok("webp") -> {
      let content = bit_array.base64_encode(content, True)
      Ok(tool.Return("", [content]))
    }
    _ -> {
      case bit_array.to_string(content) {
        Ok(content) -> Ok(tool.Return(content, []))
        Error(Nil) -> Error("File not UTF-8 encoded")
      }
    }
  }
}
