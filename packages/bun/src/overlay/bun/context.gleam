import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn read_all(working_dir) {
  let dirs = parent_paths(working_dir)
  list.filter_map(dirs, read)
}

fn read(path) {
  use contents <- result.map(simplifile.read(path <> "/Agents.md"))
  #(path, contents)
}

fn parent_paths(from: String) {
  case string.split(from, "/") {
    ["", ..rest] -> {
      let #(_, mapped) =
        list.map_fold(rest, [""], fn(acc, item) {
          let current = list.append(acc, [item])
          #(current, string.join(current, "/"))
        })
      mapped
    }
    // Not absolute
    _ -> []
  }
}
