
{ omap, splitLast, escape, type } = require './rondom'


## primitives ##

error = (@irritant, @desc = '?') ->
  @path = []
  undefined

error::toString = ->
  ctx = "\n  at: .#{@path.join '.'}"
  "Reshape error:
#{@path.length and ctx or ''}
\n  expected: < #{@desc} >
\n  irritant: < #{@irritant} >"

fail = (has, desc) -> throw new error has, desc

recover = (fun, handle = ->) ->
  try fun() catch e
    if e.constructor is error
      handle e
    else throw e

annotate = (fun, emap) ->
  try fun() catch e
    emap e if e.constructor is error
    throw e

at = (path_component, fun) ->
  annotate fun, (e) -> e.path.unshift path_component

ensure = (desc, fun) ->
  fun or= opt ; desc or= "<function: #{fun}>"
  (x) -> fun(x) ? fail x, desc

satisfy = (desc, fun) ->
  fun or= opt ; desc or= "<predicate: #{fun}>"
  (x) -> (fun(x) or fail x, desc) and x

prim = { error, fail, recover, annotate, at, ensure, satisfy }


## predicates ##

proto = (p) ->
  satisfy "proto: #{p}", (x) -> Object.getPrototypeOf(x) is p

ctor = (c) ->
  satisfy "ctor: #{c}", (x) -> x.constructor is c

defined = satisfy "defined value", (x) -> x?

array   = satisfy 'array'    , type.array
object  = satisfy 'object'   , type.object
fun     = satisfy 'function' , type.function
string  = satisfy 'string'   , type.string
number  = satisfy 'number'   , type.number
boolean = satisfy 'boolean'  , type.boolean
date    = satisfy 'date'     , type.date
regex   = satisfy 'regex'    , type.regex

p = {
  proto, ctor, defined
  array, object, function: fun, string, number, boolean, date, regex
}


## combinators ##

arrayOf = (test) ->
  test = shapely test
  (arr) ->
    array arr
    arr.map (e, i) -> at i, -> test e

any = (tests...) ->
  [ pre, last ] = splitLast tests.map shapely
  (x) -> escape (esc) ->
    desc = []
    for test in pre
      recover (-> esc test x), (e) -> desc.push e.desc
    annotate (-> last x), (e) ->
      desc.push e.desc ; e.desc = desc

all = (tests...) ->
  [ pre, last ] = splitLast tests.map shapely
  (x) -> ( test x ) for test in pre ; last x

opt = (test) ->
  test = shapely test
  (x) -> recover -> test x

k = { arrayOf, any, all, opt }


## literals ##

shapely = (test) ->

  if type.function test then test
  else if type.array test
    shapely_array test
  else if type.regex test
    shapely_regex test
  else if type.object test
    shapely_object test
  else shapely_prim test

shapely_array = (test_a) ->
  test_a = test_a.map shapely
  (arr) ->
    array arr
    test_a.map (test, i) -> at i, -> test arr[i]

shapely_object = (test_o) ->
  test_o = omap test_o, shapely
  (obj) ->
    object obj
    omap test_o, (test, key) -> at key, -> test obj[key]

shapely_regex = (test_re) ->
  check = ensure test_re, (x) -> ( x.match(test_re) || [] )[0]
  (str) -> string str ; check str

shapely_prim = (test_p) ->
  satisfy test_p, (x) -> x is test_p



module.exports = { shapely, prim, p, k }

