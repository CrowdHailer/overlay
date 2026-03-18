import filepath
import gleam/option.{type Option, None, Some}
import gleam/result.{try}
import overlay/llm/provider
import overlay/llm/provider/ollama
import overlay/system

pub type Config {
  Config(
    provider: provider.Provider,
    model: String,
    system_prompt: String,
    root: String,
  )
}

fn default_model(provider) {
  case provider {
    provider.Ollama(ollama.Config(api_key: None, ..)) -> "qwen3.5:35b"
    provider.Ollama(ollama.Config(api_key: Some(_), ..)) -> "qwen3.5:397b-cloud"
    provider.Mistral(_) -> "ministral-3b-2512"
  }
}

pub fn from_args(
  arguments: List(String),
  current_directory: String,
) -> Result(#(String, fn(provider.Provider) -> Config), String) {
  use Args(dir:, provider:) <- try(do_args(arguments, Args("", None)))
  use root <- try(resolve_root(current_directory, dir))
  let system_prompt = system.build_prompt(root)
  let resume = fn(provider) {
    let model = default_model(provider)
    Config(provider:, model:, system_prompt:, root:)
  }
  Ok(#(provider |> option.unwrap(""), resume))
}

fn do_args(args, state) {
  case args, state {
    [], _ -> Ok(state)
    ["--provider", provider, ..rest], Args(provider: None, ..) ->
      do_args(rest, Args(..state, provider: Some(provider)))
    ["--provider=" <> provider, ..rest], Args(provider: None, ..) ->
      do_args(rest, Args(..state, provider: Some(provider)))
    ["--" <> flag, ..], _ -> Error("unknown flag: " <> flag)
    [dir, ..rest], state -> do_args(rest, Args(..state, dir:))
  }
}

pub type Args {
  Args(dir: String, provider: Option(String))
}

fn resolve_root(current_directory, working) {
  let joined = case filepath.is_absolute(working) {
    True -> working
    False -> filepath.join(current_directory, working)
  }

  filepath.expand(joined) |> result.replace_error("invalid working directory")
}
