
exports = module.exports

exports.omap = (obj, fun) ->
  res = {}
  for key, value of obj
    ( value1 = fun value, key )? and ( res[key] = value1 )
  res

exports.splitLast = (arr) ->
  len = arr.length
  [ arr[0 ... len - 1], arr[len - 1] ]

exports.escape = (f) ->
  res      = null
  sentinel = Object.create null
  try f (val) -> res = val ; throw sentinel
  catch e
    if e is sentinel then res else throw e

typeof_ = (typerep) -> (x) -> typeofx is typerep

exports.type =
  array  : Array.isArray
  object : (x) -> x is Object x

[ ['regex', RegExp], ['date' , Date  ] ] .forEach ([ name, ctor ]) ->
  exports.type[name] = (x) -> x instanceof ctor

[ 'function', 'string', 'number', 'boolean' ] .forEach (rep) ->
  exports.type[rep] = (x) -> typeof x is rep

