import gleam/fetch
import gleam/int
import gleam/io
import gleam/javascript/promise
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam_community/ansi
import overlay/config.{Config}
import overlay/llm/chat
import overlay/llm/provider
import overlay/llm/tool
import overlay/tools

pub fn stream(
  config: config.Config,
  history: List(chat.Message(tool.Call)),
) -> promise.Promise(Result(chat.Completion(tool.Call), String)) {
  let Config(provider:, model:, system_prompt:, ..) = config
  let request =
    provider.stream_completion_request(
      provider,
      model,
      system_prompt,
      list.reverse(history),
      tools.specs(),
    )
  use return <- promise.await(fetch.send_bits(request))
  use response <- promise.try_sync(return |> result.map_error(string.inspect))

  case response.status {
    200 -> {
      use reader <- promise.try_sync(
        fetch.bytes_reader(response) |> result.map_error(string.inspect),
      )
      do_stream(reader, provider, <<>>, chat.fresh())
    }
    status -> {
      use body <- promise.await(fetch.read_text_body(response))
      let reason = case body {
        Ok(response) -> "Failed to reach llm: " <> response.body
        Error(_) -> "Failed to call llm, status: " <> int.to_string(status)
      }
      promise.resolve(Error(reason))
    }
  }
}

fn do_stream(reader, provider, buffer, completion) {
  use chunk <- promise.await(fetch.next_bytes(reader))
  case chunk {
    Error(_) -> promise.resolve(Error("llm interrupted"))
    Ok(None) -> promise.resolve(Ok(completion))
    Ok(Some(bytes)) -> {
      let #(new, buffer) =
        provider.completion_chunk_parse(provider, buffer, bytes)
      io.print(print_progress(new))
      let completion = chat.append_chunks(completion, new)
      do_stream(reader, provider, buffer, completion)
    }
  }
}

fn print_progress(new) {
  let temporary = chat.append_chunks(chat.fresh(), new)

  case temporary.thinking {
    "" -> ""
    thought -> ansi.dim(thought)
  }
  <> case temporary.content {
    "" -> ""
    thought -> thought
  }
}

pub fn result_to_message(
  call_id: String,
  result: Result(tool.Return, String),
) -> chat.Message(a) {
  case result {
    Ok(tool.Return(text, images)) -> {
      chat.ToolResultMessage(tool_call_id: call_id, text:, images:)
    }
    Error(reason) ->
      chat.ToolResultMessage(tool_call_id: call_id, text: reason, images: [])
  }
}
