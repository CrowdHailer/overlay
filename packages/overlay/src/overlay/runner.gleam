//// Maps evaluation break to useful actions or failure.
//// i.e. is the effect know or unknown.

import eyg/interpreter/break
import eyg/interpreter/expression
import eyg/interpreter/value
import multiformats/cid/v1

pub type Return(t, e, a, b) {
  Done(t)
  Fail(break.Reason(a, b))
  DoEffect(effect: e, resume: fn(value.Value(a, b)) -> Return(t, e, a, b))
  LookupReference(
    reference: v1.Cid,
    resume: fn(value.Value(a, b)) -> Return(t, e, a, b),
  )
  LookupRelease(
    package: String,
    release: Int,
    module: v1.Cid,
    resume: fn(value.Value(a, b)) -> Return(t, e, a, b),
  )
}

pub type Effect(e, reply, a, b) {
  External(lift: e)
  Reply(value.Value(a, b))
}

pub fn expression(source, parse_effect) {
  loop(expression.execute(source, []), expression.resume, parse_effect)
}

fn loop(return, resume, parse_effect) {
  case return {
    Ok(return) -> Done(return)
    Error(#(reason, _meta, env, k)) ->
      case reason {
        break.UndefinedReference(reference) -> {
          let resume = fn(value) {
            loop(resume(value, env, k), resume, parse_effect)
          }
          LookupReference(reference:, resume:)
        }
        break.UndefinedRelease(package:, release:, module:) -> {
          let resume = fn(value) {
            loop(resume(value, env, k), resume, parse_effect)
          }
          LookupRelease(package:, release:, module:, resume:)
        }
        break.UnhandledEffect(label, lift) ->
          case parse_effect(label, lift) {
            Ok(External(effect)) -> {
              let resume = fn(value) {
                loop(resume(value, env, k), resume, parse_effect)
              }
              DoEffect(effect:, resume:)
            }
            Ok(Reply(value)) ->
              loop(resume(value, env, k), resume, parse_effect)
            Error(reason) -> Fail(reason)
          }
        reason -> Fail(reason)
      }
  }
}
