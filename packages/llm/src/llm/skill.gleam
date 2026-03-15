import gleam/list
import gleam/string
import mork

pub type Document {
  Document(name: String, description: String, content: String)
}

pub fn parse(content) {
  let #(front, content) = mork.split_frontmatter_from_input(content)
  let lines = string.split(front, "\n")
  let name = case get_field(lines, "name") {
    Ok(name) -> name
    _ -> panic
  }
  let description = case get_field(lines, "description") {
    Ok(description) -> description
    _ -> panic
  }
  Ok(Document(name:, description:, content:))
}

fn get_field(lines, key) {
  list.find_map(lines, fn(line) {
    case string.split_once(line, ":") {
      Ok(#(k, value)) if k == key -> Ok(string.trim(value))
      _ -> Error(Nil)
    }
  })
}

const preamble = [
  "\n\nThe following skills provide specialized instructions for specific tasks.",
  "Use the read tool to load a skill's file when the task matches its description.",
  "When a skill file references a relative path, resolve it against the skill directory (parent of SKILL.md / dirname of the path) and use that absolute path in tool commands.",
  "",
  "<available_skills>",
]

pub fn format_skills_for_prompt(skills) {
  case skills {
    [] -> ""
    _ -> {
      let skills =
        list.flat_map(skills, fn(skill) {
          let #(location, Document(name:, description:, ..)) = skill

          [
            "  <skill>",
            "    <name>" <> escape_xml(name) <> "</name>",
            "    <description>" <> escape_xml(description) <> "</description>",
            "    <location>" <> escape_xml(location) <> "</location>",
            "  </skill>",
          ]
        })
      list.flatten([preamble, skills, ["</available_skills>"]])
      |> string.join("\n")
    }
  }
}

fn escape_xml(str) {
  str
  |> string.replace("&", "&amp;")
  |> string.replace("<", "&lt;")
  |> string.replace(">", "&gt;")
  |> string.replace("\"", "&quot;")
  |> string.replace("'", "&apos;")
}
