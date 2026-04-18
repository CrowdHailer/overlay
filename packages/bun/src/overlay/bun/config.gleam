import argv
import envoy
import gleam/result.{try}
import overlay/config
import overlay/llm/provider
import overlay/llm/provider/mistral
import overlay/llm/provider/ollama
import simplifile

pub fn load(
  context_files: List(#(String, String)),
) -> Result(config.Config, String) {
  use current_directory <- try(
    simplifile.current_directory()
    |> result.map_error(simplifile.describe_error),
  )

  use #(provider, continue) <- try(config.from_args(
    argv.load().arguments,
    current_directory,
    context_files,
  ))

  case provider {
    "" | "ollama" -> Ok(continue(provider.Ollama(ollama.local())))

    "ollama.com" -> {
      use token <- result.map(get_env("OLLAMA_API_KEY"))
      continue(provider.Ollama(ollama.cloud(token)))
    }

    "mistral" -> {
      use token <- result.map(get_env("MISTRAL_API_KEY"))
      continue(provider.Mistral(mistral.Config(token)))
    }

    _ -> Error("unknown provider: " <> provider)
  }
}

pub fn get_env(key) {
  envoy.get(key)
  |> result.replace_error("missing environment variable: " <> key)
}
