import gleam/dict
import multiformats/cid/v1
import overlay/bun/helpers
import overlay/bun/tools/eval
import overlay/bun/tools/state
import overlay/config
import overlay/llm/provider
import overlay/llm/provider/ollama

pub fn simple_script_test() {
  let assert eval.Done(Ok(value)) =
    "!int_add(2, 3)"
    |> run()
  assert "5" == value
}

pub fn syntax_error_test() {
  let assert eval.Done(Error(reason)) =
    "!"
    |> run()
  assert "Unexpected end of program" == reason
}

pub fn failure_test() {
  let assert eval.Done(Error(reason)) =
    "!magic"
    |> run()
  assert "builtin undefined: !magic" == reason
}

pub fn reference_test() {
  let cid = helpers.cid_from_source("!int_add(1)")
  let assert eval.Done(Error(reason)) =
    { "#" <> v1.to_string(cid) <> "(3)" }
    |> run()
  assert "direct reference lookup unsupported" == reason
}

pub fn release_test() {
  let assert eval.Done(Error(reason)) =
    "@standard"
    |> run()
  assert "release lookup unsupported" == reason
}

pub fn effect_test() {
  let assert eval.Read(path:, resume:) =
    "perform Read(\"hello.md\")"
    |> run()
  assert "hello.md" == path
  let assert #(_, eval.Done(Ok(value))) = resume(Ok(<<"some text">>))
  assert "Ok(Binary(9 bytes): c29tZSB0ZXh0)" == value
}

pub fn bad_args_to_effect_test() {
  let assert eval.Done(Error(reason)) =
    "perform Read(3)"
    |> run()
  assert "unexpected term, expected: String got: 3" == reason
}

pub fn abort_test() {
  let assert eval.Done(Error(reason)) =
    "!never(perform Abort(\"aborted\"))"
    |> run()
  assert "Aborted with reason: \"aborted\"" == reason
}

pub fn unknown_effect_test() {
  let assert eval.Done(Error(reason)) =
    "perform Foo(2)"
    |> run()
  assert "unhandled effect Foo(2)" == reason
}

/// run with a clean cache of tokens
fn run(code) {
  let state =
    state.State(config: config.Config(
      provider: provider.Ollama(ollama.local()),
      model: "example-12b",
      system_prompt: "",
      root: "/tmp",
      skills: dict.new(),
    ))
  let #(_store, return) = eval.run(code, state)
  return
}
