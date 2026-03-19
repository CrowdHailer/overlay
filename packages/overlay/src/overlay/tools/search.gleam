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

import gleam/http
import gleam/http/request
import gleam/http/response.{Response}
import gleam/int
import gleam/json
import gleam/option.{None}

pub fn sans_io(token, query) {
  let request =
    request.Request(
      method: http.Post,
      headers: [#("authorization", "Bearer " <> token)],
      body: json.to_string(json.object([#("query", json.string(query))])),
      scheme: http.Https,
      host: "ollama.com",
      port: None,
      path: "/api/web_search",
      query: None,
    )

  let resume = fn(response) {
    case response {
      Response(status: 200, body:, ..) -> {
        case json.parse(body, decoder()) {
          Ok(_results) -> Ok(tool.Return(text: body, images: []))
          Error(_) -> Error("failed to decode results of search.")
        }
      }
      Response(status:, body:, ..) ->
        Error(
          "unexpected response status: "
          <> int.to_string(status)
          <> "\n\n"
          <> body,
        )
    }
  }
  #(request, resume)
}

pub type Return {
  Return(title: String, url: String, content: String)
}

fn decoder() {
  use results <- decode.field(
    "results",
    decode.list({
      use title <- decode.field("title", decode.string)
      use url <- decode.field("url", decode.string)
      use content <- decode.field("content", decode.string)
      decode.success(Return(title:, url:, content:))
    }),
  )
  decode.success(results)
}
