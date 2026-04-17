import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}
import gleam/result.{try}
import overlay/filepathx
import overlay/llm/provider
import overlay/llm/provider/ollama
import overlay/skills
import overlay/system

pub type Config {
  Config(
    mode: Mode,
    provider: provider.Provider,
    model: String,
    system_prompt: String,
    root: String,
    skills: Dict(String, skills.Document),
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
  let #(mode, arguments) = case arguments {
    ["ralph", ..rest] -> #(Ralph, rest)
    _ -> #(Chat, arguments)
  }
  use Args(dir:, provider:, mode:) <- try(do_args(
    arguments,
    Args("", None, mode:),
  ))
  use root <- try(filepathx.resolve_relative(current_directory, dir))
  let system_prompt = system.build_prompt(root)
  let resume = fn(provider) {
    let model = default_model(provider)
    Config(mode:, provider:, model:, system_prompt:, root:, skills: dict.new())
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
  Args(dir: String, provider: Option(String), mode: Mode)
}

pub type Mode {
  Chat
  Ralph
}
