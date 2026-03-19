import castor
import gleam/dynamic/decode
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/result
import gleam/uri
import oas/generator/utils
import overlay/llm/tool

pub const name = "get"

pub const description = "Get the content at the provided url"

pub fn parameters() {
  [castor.field("url", castor.string())]
}

pub fn spec() {
  tool.Tool(name, description, parameters())
}

pub fn cast(arguments) {
  let arguments = utils.fields_to_dynamic(arguments)
  let decoder = {
    decode.field("url", decode.string, decode.success)
  }
  decode.run(arguments, decoder)
}

pub fn sans_io(url) {
  use url <- result.try(uri.parse(url) |> result.replace_error("invalid url"))
  use request <- result.try(
    request.from_uri(url) |> result.replace_error("invalid url"),
  )
  let resume = fn(response: Response(_)) {
    tool.Return(text: response.body, images: [])
  }
  Ok(#(request, resume))
}
