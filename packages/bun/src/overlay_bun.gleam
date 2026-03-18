import argv
import envoy
import gleam/io
import gleam/result
import overlay/config
import overlay/llm/provider
import overlay/llm/provider/mistral
import overlay/llm/provider/ollama
import simplifile

pub fn main() -> Nil {
  use current_directory <- try(
    simplifile.current_directory()
    |> result.map_error(simplifile.describe_error),
  )

  use #(provider, continue) <- try(config.from_args(
    argv.load().arguments,
    current_directory,
  ))

  use config <- try(case provider {
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
  })
  io.println("started overlay in dir: " <> config.root)
}

fn get_env(key) {
  envoy.get(key)
  |> result.replace_error("missing environment variable: " <> key)
}

fn try(result, then) {
  case result {
    Ok(value) -> then(value)
    Error(reason) -> {
      io.println(reason)
    }
  }
}
