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

import eyg/interpreter/break
import eyg/interpreter/simple_debug
import eyg/interpreter/value as v
import eyg/ir/dag_json
import eyg/parser/parser
import filepath
import gleam/fetch
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/result
import gleam/string
import ogre/operation
import ogre/origin
import overlay/bun/tools/state.{type State}
import overlay/filepathx
import overlay/runner as r
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
    r.Done(value) -> #(store, Done(Ok(simple_debug.inspect(value))))
    r.Fail(reason) -> #(store, Done(Error(simple_debug.describe(reason))))
    r.DoEffect(effect:, resume:) ->
      case effect {
        eval.DirectFetch(service:, operation:) -> {
          let resume = fn(token_result) {
            case token_result {
              Ok(token) -> {
                let request = service_request(service, operation, token)
                let resume = fn(result) {
                  let result = result.map_error(result, string.inspect)
                  loop(resume(tg_fetch.encode(result)), store)
                }
                #(store, Fetch(request:, resume:))
              }
              Error(reason) -> loop(resume(v.error(v.String(reason))), store)
            }
          }
          // Return as direct fetch to the top
          #(store, Authorize(service:, resume:))
        }
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
    r.LookupReference(reference: _, resume: _) -> #(
      store,
      Done(Error("direct reference lookup unsupported")),
    )
    r.LookupRelease(package:, release:, module: _, resume:) ->
      // I want to pass in a cwd of "." but the expand path logic errors if going above root.
      lookup_release(package, release, resume, store, store.config.root)
  }
}

fn lookup_release(package, release, resume, store, cwd) {
  case package, release {
    "./" <> _, 0 | "/" <> _, 0 | "../" <> _, 0 -> {
      case filepathx.resolve_relative(cwd, package) {
        Ok(path) -> {
          let resume = fn(result) {
            case result {
              Ok(bytes) ->
                case json.parse_bits(bytes, dag_json.decoder(Nil)) {
                  Ok(source) ->
                    case
                      r.expression(source, fn(label, lift) {
                        Error(break.UnhandledEffect(label, lift))
                      })
                    {
                      r.Done(value) -> loop(resume(value), store)
                      r.Fail(reason) -> #(
                        store,
                        Done(Error(simple_debug.describe(reason))),
                      )
                      r.DoEffect(effect: _, resume: _) ->
                        panic as "no effects supported"
                      r.LookupReference(..) -> #(
                        store,
                        Done(Error("nested reference lookup unsupported")),
                      )
                      r.LookupRelease(
                        package:,
                        release:,
                        module: _,
                        resume: inner,
                      ) -> {
                        let resume = compose_resume(inner, resume)
                        let cwd = filepath.directory_name(path)

                        lookup_release(package, release, resume, store, cwd)
                      }
                    }
                  Error(_) -> #(
                    store,
                    Done(Error("not a valid .eyg.json import")),
                  )
                }
              Error(reason) -> #(
                store,
                Done(Error(simplifile.describe_error(reason))),
              )
            }
          }
          #(store, Read(path:, resume:))
        }
        Error(_) -> {
          echo #(cwd, package)
          panic
        }
      }
    }
    _, _ -> #(store, Done(Error("release lookup unsupported")))
  }
}

fn compose_resume(inner, resume) {
  fn(v) {
    case inner(v) {
      // parent resume
      r.Done(v) -> resume(v)
      r.Fail(reason) -> r.Fail(reason)
      r.DoEffect(effect:, resume: inner) ->
        r.DoEffect(effect:, resume: compose_resume(inner, resume))
      r.LookupReference(reference:, resume:) ->
        r.LookupReference(reference:, resume: compose_resume(inner, resume))
      r.LookupRelease(package:, release:, module:, resume:) ->
        r.LookupRelease(
          package:,
          release:,
          module:,
          resume: compose_resume(inner, resume),
        )
    }
  }
}

fn service_request(service, operation, token) {
  let origin = case service {
    "dnsimple" -> origin.https("api.dnsimple.com")
    "github" -> origin.https("api.github.com")
    "netlify" -> origin.https("api.netlify.com")
    "tavily" -> origin.https("api.tavily.com")
    "vimeo" -> origin.https("api.vimeo.com")
    _ -> panic
  }
  operation.to_request(operation, origin)
  |> request.set_header("authorization", "Bearer " <> token)
}

pub type Return(t) =
  #(State, Effect(t))

pub type Effect(t) {
  Done(t)
  Authorize(service: String, resume: fn(Result(String, String)) -> Return(t))
  Fetch(
    request: Request(BitArray),
    resume: fn(Result(Response(BitArray), fetch.FetchError)) -> Return(t),
  )
  Read(
    path: String,
    resume: fn(Result(BitArray, simplifile.FileError)) -> Return(t),
  )
}
