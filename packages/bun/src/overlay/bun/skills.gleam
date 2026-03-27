import envoy
import filepath
import gleam/dict
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/result
import gleam/string

import overlay/skills
import simplifile

/// Read all the skills from the working directory
pub fn read_all(working_dir) {
  let dirs = skills.search_paths(working_dir)

  let extra = case envoy.get("HOME") {
    Ok(home) -> {
      simplifile.read(home <> "/.config/overlay/config.json")
      |> result.unwrap("")
      |> json.parse(config_decoder())
      |> result.unwrap([])
      |> list.map(string.replace(_, "~", home))
    }
    Error(Nil) -> []
  }

  let dirs = list.append(dirs, extra)
  list.flat_map(dirs, read)
  |> dict.from_list
}

fn config_decoder() {
  decode.field("skills", decode.list(decode.string), decode.success)
}

fn read(directory) {
  let children = simplifile.read_directory(directory) |> result.unwrap([])

  list.filter_map(children, fn(child) {
    let root_path = filepath.join(directory, child)
    let doc_path = filepath.join(root_path, "SKILL.md")
    use contents <- result.try(
      simplifile.read(doc_path)
      |> result.replace_error(Nil),
    )
    use doc <- result.try(skills.parse(contents) |> result.replace_error(Nil))
    Ok(#(root_path, doc))
  })
}
