import gleam/string
import overlay/system

pub fn reference_root_test() {
  let root = "/tmp/abc"
  system.build_prompt(root, [])
  |> string.contains(root)
}
