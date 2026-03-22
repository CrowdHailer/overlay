import filepath
import gleam/result

pub fn resolve_relative(root, relative) {
  let joined = case filepath.is_absolute(relative) {
    True -> relative
    False -> filepath.join(root, relative)
  }

  filepath.expand(joined) |> result.replace_error("invalid relative directory")
}
