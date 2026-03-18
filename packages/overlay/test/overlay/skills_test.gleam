import overlay/skills

pub fn search_path_test() {
  assert ["/skills", "/example/skills", "/example/myapp/skills"]
    == skills.search_paths("/example/myapp")
}

pub fn valid_skill_parse_test() {
  let assert Ok(document) =
    skills.parse("---\nname: my-skill\ndescription: A skill\n---\nA skill.")
  assert "my-skill" == document.name
  assert "A skill" == document.description
  assert "A skill." == document.content
}

pub fn missing_name_frontmatter_test() {
  let assert Error(skills.MissingName) =
    skills.parse("---\ndescription: A skill\n---\nA skill.")
}

pub fn missing_description_frontmatter_test() {
  let assert Error(skills.MissingDescription) =
    skills.parse("---\nname: my-skill\n---\nA skill.")
}
