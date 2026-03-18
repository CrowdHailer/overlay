import gleam/option
import ogre/origin
import overlay/config
import overlay/generators as g
import overlay/llm/provider
import overlay/llm/provider/ollama

fn dummy_provider() {
  provider.Ollama(ollama.Config(
    origin: origin.https("ollama.test"),
    api_key: option.None,
  ))
}

pub fn parse_valid_arguments_test() {
  let cwd = g.dir()

  let assert Ok(#("my-llm", continue)) =
    config.from_args([".", "--provider=my-llm"], cwd)
  let config = continue(dummy_provider())
  assert cwd == config.root
}

pub fn resolved_valid_path_test() {
  let cwd = g.dir()

  let assert Ok(#("", continue)) = config.from_args(["./foo"], cwd)
  let config = continue(dummy_provider())
  assert cwd <> "/foo" == config.root

  let assert Ok(#("", continue)) = config.from_args(["foo"], cwd)
  let config = continue(dummy_provider())
  assert cwd <> "/foo" == config.root

  let assert Ok(#("", continue)) = config.from_args(["../foo"], cwd)
  let config = continue(dummy_provider())
  assert "/tmp/foo" == config.root

  let assert Ok(#("", continue)) = config.from_args(["/foo"], cwd)
  let config = continue(dummy_provider())
  assert "/foo" == config.root
}

pub fn cant_escape_directory_test() {
  let cwd = g.dir()
  let assert Error("invalid working directory") =
    config.from_args(["/../foo"], cwd)

  let assert Error("invalid working directory") =
    config.from_args(["../../../foo"], cwd)
}
