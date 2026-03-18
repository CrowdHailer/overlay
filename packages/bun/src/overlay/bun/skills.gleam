import filepath
import gleam/dict
import gleam/list
import gleam/result

import overlay/skills
import simplifile

/// Read all the skills from the working directory
pub fn read_all(working_dir) {
  list.flat_map(skills.search_paths(working_dir), read)
  |> dict.from_list
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
