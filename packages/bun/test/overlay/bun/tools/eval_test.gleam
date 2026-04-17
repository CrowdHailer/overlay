import eyg/ir/dag_json
import eyg/ir/tree as ir
import gleam/dict
import multiformats/cid/v1
import overlay/bun/helpers
import overlay/bun/tools/eval
import overlay/bun/tools/state
import overlay/config
import overlay/llm/provider
import overlay/llm/provider/ollama
import simplifile

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
  let assert eval.ReadFile(input:, resume:) =
    "perform ReadFile({path: \"hello.md\", offset: 0, limit: 100000})"
    |> run()
  assert "hello.md" == input.path
  let assert #(_, eval.Done(Ok(value))) = resume(Ok(<<"some text">>))
  assert "Ok(Binary(9 bytes): c29tZSB0ZXh0)" == value
}

pub fn bad_args_to_effect_test() {
  let assert eval.Done(Error(reason)) =
    "perform ReadFile(3)"
    |> run()
  assert "unexpected term, expected: Record got: 3" == reason
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

pub fn relative_reference_test() {
  let assert eval.ReadFile(input:, resume:) =
    "import \"./foo.eyg.json\""
    |> run()
  assert "/tmp/foo.eyg.json" == input.path

  let assert #(_state, eval.Done(Ok(value))) =
    resume(Ok(<<"{\"0\":\"i\",\"v\":15}">>))
  assert "15" == value
}

pub fn import_unknown_reference_test() {
  let assert eval.ReadFile(input:, resume:) =
    "import \"./unknown.eyg.json\""
    |> run()
  assert "/tmp/unknown.eyg.json" == input.path

  let assert #(_state, eval.Done(Error(reason))) =
    resume(Error(simplifile.NotUtf8))
  assert "File not UTF-8 encoded" == reason
}

pub fn import_malformed_reference_test() {
  let assert eval.ReadFile(input:, resume:) =
    "import \"./bad.eyg.json\""
    |> run()
  assert "/tmp/bad.eyg.json" == input.path

  let assert #(_state, eval.Done(Error(reason))) = resume(Ok(<<>>))
  assert "not a valid .eyg.json import" == reason
}

pub fn relative_module_not_sound_test() {
  let assert eval.ReadFile(input:, resume:) =
    "import \"./unsound.eyg.json\""
    |> run()
  assert "/tmp/unsound.eyg.json" == input.path

  let assert #(_state, eval.Done(Error(reason))) =
    resume(Ok(<<"{\"0\":\"z\"}">>))
  assert "tried to run a todo" == reason
}

pub fn follows_relative_reference_test() {
  let assert eval.ReadFile(input:, resume:) =
    "let {x: x} = import \"./lib/index.eyg.json\"
    x"
    |> run()
  assert "/tmp/lib/index.eyg.json" == input.path

  let source =
    ir.release("../bar.eyg.json", 0, dag_json.vacant_cid)
    |> dag_json.to_string

  let assert #(_state, eval.ReadFile(input:, resume:)) =
    resume(Ok(<<source:utf8>>))
  assert "/tmp/bar.eyg.json" == input.path
  let source =
    ir.record([#("x", ir.integer(10))])
    |> dag_json.to_string
  let assert #(_state, eval.Done(Ok(value))) = resume(Ok(<<source:utf8>>))
  assert "10" == value
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
