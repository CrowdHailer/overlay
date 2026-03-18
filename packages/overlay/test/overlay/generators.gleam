import gleam/int
import gleam/list
import gleam/string

const letters = [
  "a",
  "b",
  "c",
  "d",
  "e",
  "f",
  "g",
  "h",
  "i",
  "j",
  "k",
  "l",
  "m",
  "n",
  "o",
  "p",
  "q",
  "r",
  "s",
  "t",
  "u",
  "v",
  "w",
  "x",
  "y",
  "z",
]

pub fn dir() {
  "/tmp/" <> word()
}

pub fn word() {
  int.random(5) + 2
  |> repeatedly(fn() { list.sample(letters, 1) })
  |> list.flatten
  |> string.concat
}

pub fn words(length) {
  repeatedly(length, word)
  |> string.join(" ")
}

pub fn prompt() {
  let length = int.random(10) + 3
  words(length)
}

// pub fn rfc339(offset) {
//   let timestamp = timestamp.from_unix_seconds(1_771_070_982 + offset)
//   timestamp.to_rfc3339(timestamp, duration.seconds(0))
// }

pub fn repeatedly(times: Int, generator: fn() -> a) -> List(a) {
  int.range(0, times, [], fn(acc, _) { [generator(), ..acc] })
  |> list.reverse
}
