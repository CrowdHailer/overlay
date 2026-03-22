//// This module maps the sans io effects from the implementation of the runner to those available to the overlay_bun application.
//// 
//// There several nested levels to the concept of effect. Starting innermost.
//// 1. The EYG effects available to the script being run.
//// 2. Effects that the runner my return. This includes external from 1. combined with looking up code by reference/release.
//// 3. The top level effects that should be actioned by the overlay_bun application,
////    this may be less that at 2. For example if the store has a cached version of the code loaded already
//// 
//// There is a design tension here.
//// 
//// Effects (3.) could be pushed into the core overlay library on the assumption that overlay_bun and overlay_web operate in equivalent environments.
//// This would be nice for teaching use of overlay in the web and it moving over to a native install.
//// 
//// Effects (1.) available to the script could be parameterised in the core overlay/tools/eval module.
//// This would allow overlay assistants to be written for completly different environment.s
//// 
//// The first option would increase the code that could be resused for example handling file reading etc.
//// The first option would also limit flexibility as it is totally incompatible with the direction in the second option.
//// 
//// Maybe it makes sense to pass in a parse_effect function that is already parameterised to top level actions.
//// The runner effects could then be unwrapped in the loop at this level. However that would force semantics of external effects further into the core evaluation logic

import eyg/interpreter/simple_debug
import eyg/parser/parser
import gleam/fetch
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/result
import gleam/string
import overlay/bun/tools/state.{type State}
import overlay/runner
import overlay/tools/eval
import simplifile
import touch_grass/fetch as tg_fetch
import touch_grass/read

pub fn run(code: String, store: State) -> Return(Result(String, String)) {
  case eval.sans_io(code) {
    Ok(return) -> {
      loop(return, store)
    }
    Error(reason) -> #(store, Done(Error(parser.describe_reason(reason))))
  }
}

fn loop(return, store) {
  case return {
    runner.Done(value) -> #(store, Done(Ok(simple_debug.inspect(value))))
    runner.Fail(reason) -> #(store, Done(Error(simple_debug.describe(reason))))
    runner.DoEffect(effect:, resume:) ->
      case effect {
        eval.Fetch(request:) -> {
          let resume = fn(result) {
            let result = result.map_error(result, string.inspect)
            loop(resume(tg_fetch.encode(result)), store)
          }
          #(store, Fetch(request:, resume:))
        }
        eval.Read(path) -> {
          let resume = fn(result) {
            let result = result.map_error(result, simplifile.describe_error)
            loop(resume(read.encode(result)), store)
          }
          #(store, Read(path:, resume:))
        }
      }
    runner.LookupReference(reference: _, resume: _) -> #(
      store,
      Done(Error("direct reference lookup unsupported")),
    )
    runner.LookupRelease(..) -> #(
      store,
      Done(Error("release lookup unsupported")),
    )
  }
}

pub type Return(t) =
  #(State, Effect(t))

pub type Effect(t) {
  Done(t)
  Fetch(
    request: Request(BitArray),
    resume: fn(Result(Response(BitArray), fetch.FetchError)) -> Return(t),
  )
  Read(
    path: String,
    resume: fn(Result(BitArray, simplifile.FileError)) -> Return(t),
  )
}
