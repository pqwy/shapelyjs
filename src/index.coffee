
{ omap, splitLast, escape, type } = require './rondom'


## primitives ##

error = (@irritant, @desc) ->
  @path = []
  undefined

error::toString = ->
  ctx = "\n  at: .#{@path.join '.'}"
  "Reshape error:
#{@path.length and ctx or ''}
\n  expected: < #{@desc ? '?'} >
\n  irritant: < #{@irritant} >"

fail = (has, desc) -> throw new error has, desc

recover = (fun, handle = ->) ->
  try fun.call @ catch e
    if e.constructor is error
      handle.call @, e
    else throw e

annotate = (fun, emap) ->
  try fun.call @ catch e
    emap.call @, e if e.constructor is error
    throw e

at = (path_component, fun) ->
  annotate.call @, fun, (e) -> e.path.unshift path_component

ensure = (desc, fun) ->
  (x) -> fun.call(@, x) ? fail x, desc

satisfy = (desc, fun) ->
  (x) -> (fun.call(@, x) or fail x, desc) and x

prim = { error, fail, recover, annotate, at, ensure, satisfy }


## predicates ##

p =

  proto: (p) ->
    satisfy "proto: #{p}", (x) ->
      Object.getPrototypeOf(x) is p

  ctor: (c) ->
    satisfy "ctor: #{c}", (x) ->
      x.constructor is c

  defined: satisfy("defined value", (x) -> x?)

[ 'array', 'object', 'function', 'string'
, 'number', 'boolean', 'date', 'regex'
] .forEach (rep) -> p[rep] = satisfy rep, type[rep]


## combinators ##

k =

  arrayOf: (test) ->
    test = shapely test
    (arr) ->
      p.array arr
      arr.map (e, i) => at i, => test.call @, e

  any: (tests...) ->
    [ pre, last ] = splitLast tests.map shapely
    (x) -> escape (esc) =>
      desc = []
      for test in pre
        recover (=> esc test.call @, x), (e) -> desc.push e.desc
      annotate (=> last.call @, x), (e) ->
        desc.push e.desc ; e.desc = desc

  all: (tests...) ->
    [ pre, last ] = splitLast tests.map shapely
    (x) ->
      ( test.call @, x ) for test in pre
      last.call @, x

  opt: (test) ->
    test = shapely test
    (x) -> recover => test.call @, x

  ctx: (ctx, test) -> (x) -> test.call ctx, x


## literals ##

lit =

  array: (arr_t) ->
    arr_t = arr_t.map shapely
    (arr) ->
      p.array arr
      arr_t.map (test, i) => at i, => test.call @, arr[i]

  object: (obj_t) ->
    obj_t = omap obj_t, shapely
    (obj) ->
      p.object obj
      omap obj_t, (test, key) => at key, => test.call @, obj[key]

  regex: (re) ->
    check = ensure re, (x) -> ( x.match(re) || [] )[0]
    (str) -> p.string str ; check str

  atom: (atom) ->
    satisfy atom, (x) -> x is atom


shapely = (test) ->

  if type.function test then test
  else if type.array test
    lit.array test
  else if type.regex test
    lit.regex test
  else if type.object test
    lit.object test
  else lit.atom test



module.exports = {
  shapely, prim, p, k
, sat: prim.satisfy, ens: prim.ensure
}

