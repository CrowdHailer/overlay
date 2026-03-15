import gleam/http/request.{type Request}
import llm/chat
import llm/provider/mistral
import llm/provider/ollama
import llm/tool

pub type Provider {
  Ollama(ollama.Config)
  Mistral(mistral.Config)
}

pub fn completion_request(
  provider,
  model,
  system_prompt,
  history,
  tools,
) -> Request(BitArray) {
  case provider {
    Ollama(config) ->
      ollama.completion_request(config, model, system_prompt, history, tools)
    Mistral(_config) -> panic as "unsupported"
  }
}

pub fn stream_completion_request(
  provider,
  model,
  system_prompt,
  history: chat.History,
  tools,
) -> Request(BitArray) {
  case provider {
    Ollama(config) ->
      ollama.stream_completion_request(
        config,
        model,
        system_prompt,
        history,
        tools,
      )

    Mistral(config) ->
      mistral.stream_completion_request(
        config,
        model,
        system_prompt,
        history,
        tools,
      )
  }
}

pub fn completion_chunk_parse(
  provider: Provider,
  remaining: BitArray,
  chunk: BitArray,
) -> #(List(chat.Completion(tool.Call)), BitArray) {
  case provider {
    Ollama(..) -> ollama.completion_chunk_parse(remaining, chunk)
    // Bedrock(..) -> bedrock.completion_chunk_parse(remaining, chunk)
    Mistral(..) -> mistral.completion_chunk_parse(remaining, chunk)
  }
}
