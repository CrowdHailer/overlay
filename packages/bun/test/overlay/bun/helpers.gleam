import eyg/ir/cid
import eyg/parser
import gleam/crypto

pub fn cid_from_source(source) {
  let assert Ok(source) = parser.all_from_string(source)
  let cid.Sha256(bytes:, resume:) = cid.from_tree(source)
  resume(crypto.hash(crypto.Sha256, bytes))
}

pub fn cid_from_tree(source) {
  let cid.Sha256(bytes:, resume:) = cid.from_tree(source)
  resume(crypto.hash(crypto.Sha256, bytes))
}
