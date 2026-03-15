import overlay/llm/skill

pub fn valid_skill_parse_test() {
  let assert Ok(document) =
    skill.parse("---\nname: my-skill\ndescription: A skill\n---\nA good skill.")
  assert "my-skill" == document.name
  assert "A skill" == document.description
  assert "A good skill." == document.content
}

pub fn missing_name_frontmatter_test() {
  let assert Error(skill.MissingName) =
    skill.parse("---\ndescription: A skill\n---\nA good skill.")
}

pub fn missing_description_frontmatter_test() {
  let assert Error(skill.MissingDescription) =
    skill.parse("---\nname: my-skill\n---\nA good skill.")
}
