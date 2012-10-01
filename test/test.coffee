
{ prim, p, k, shapely } = require '../lib/index'


assert = require 'assert'

ok = (validator, object, output) ->
  result = null
  assert.doesNotThrow (-> result = validator object),
    prim.error, "#{validator} rejected #{object}"
  assert.deepEqual result, (output ? object)

nok = (validator, object) ->
  assert.throws (-> validator object),
    prim.error, "#{validator} accepted #{object}"


describe 'primitives', ->

  describe '#satisfy', ->

    v1 = prim.satisfy "x > 33", (x) -> x > 33
    v2 = prim.satisfy "has .desu", ({ desu }) -> desu
    v3 = prim.satisfy "falsy", -> 0

    it 'should leave valid values intact on true', ->
      ok v1, 34
      ok v2, desu: 'x', wat: 'y'

    it 'should reject when falsy', ->
      nok v1, 32
      nok v2, wat: 'z'
      nok v3, 'x'

  describe '#ensure', ->

    v1 = prim.ensure "pluck .xyz", (obj) -> obj?.xyz
    v2 = prim.ensure "is 7", (x) -> if x == 7 then 'poo'

    it 'should accept new value when returning defined', ->
      ok v1, { abc: 123, xyz: 777 }, 777
      ok v2, 7, 'poo'

    it 'should reject when returning undefined', ->
      nok v1, { abc: 123 }
      nok v2, 8

zoo =
  array    : ['this', 'that']
  object   : up: 1, down: 0
  regex    : /oh, snap!/
  date     : new Date
  function : ->
  string   : '\\O/ _O/'
  number   : -8
  boolean  : false

otypes = [ 'array', 'object', 'regex', 'date', 'function' ]

describe 'predicates', ->

  describe 'simple type predicates', ->

    for type, example of zoo when type isnt 'object'

      it "should recognize only their type: #{type}", ->

        ok p[type], example

        for type2, example of zoo when type isnt type2
          nok p[type], example

  describe '#object', ->

    it 'should have a wide coverage', ->
      for type in otypes
        ok p.object, zoo[type]

    it 'should know when to stop', ->
      for type, example of zoo when not type in otypes
        nok p.object, example

  describe '#defined', ->

    it 'should do its stuff', ->

      ok p.defined, 119
      nok p.defined, undefined
      nok p.defined, null

  describe '#proto', ->

    it 'should recognize by prototype identity', ->

      ob = {}
      v  = p.proto ob

      ok v, Object.create ob
      nok v, {}

  describe '#ctor', ->

    it 'should recognize by constructor identity', ->

      fun = ->
      v = p.ctor fun

      ok v, new fun
      nok v, {}
      nok v, new ->


describe 'literal construction', ->

  describe '#shapely', ->

    it 'should lift simple values', ->

      v1 = shapely 3
      v2 = shapely false
      v3 = shapely "poo"

      ok v1, 3
      ok v2, false
      ok v3, "poo"

      nok v1, 8
      nok v2, "poof"
      nok v3, "WHAT?"

    it 'should lift functions into pure mappers', ->

      v1 = shapely (x) -> x
      v2 = shapely (x) -> 'foo'
      v3 = shapely (x) -> false
      v4 = shapely (x) -> undefined

      ok v1, 3
      ok v2, 3, 'foo'
      ok v3, 3, false
      assert typeof(v4 3) is 'undefined'

    it 'should recognize regexes', ->

      v1 = shapely /^a$/
      v2 = shapely /a+/

      ok v1, 'a'
      ok v2, 'xnaag', 'aa'

      nok v1, 1
      nok v1, nope: 'nope'

    it 'should lift arrays', ->

      v1 = shapely [1, 2]
      v2 = shapely [p.number, p.string]


      ok v1, [1, 2]
      ok v2, [2, 'desu']

      nok v1, 'x'
      nok v2, 17

      nok v1, [8, 2]
      nok v1, [1]
#        nok v1, [1, 2, 3]
      nok v2, [false, 'desu']
      nok v2, [3, false]

    describe 'object lifting', ->

      v1 = shapely abc: p.number, def: [p.number]

      it 'should work, basically', ->

        ok v1, abc: 3, def: [7]

        nok v1, abc: 'x', def: [0]
        nok v1, abc:  0 , def:  0
        nok v1, abc:  0 , xyz:  7
        nok v1, def: [0], xyz:  7

      it 'should ignore extra properties', ->
        ok v1,
          abc: 0, def: [0], xyz: 99
        , abc: 0, def: [0]

      it 'should erase properties mapped to null or undefined', ->

        v2 = shapely
          abc: (x) -> x + 1
          def: (x) -> undefined
          ghe: (x) -> null

        ok v2,
          abc: 1, def: 'poo', ghe: 'poo', xyz: 2
        , abc: 2

      it 'should be recursive over object and array literals', ->

        v3 = shapely
          x : p.number
          y : [p.string]
          z :
            a : [p.string]
            b :
              p : p.number
            c : [ foo: p.string ]
        
        ok v3,
          x : 1
          y : ['yay']
          z :
            a : ['wow']
            b : { p: 1 }
            c : [ { foo: 'smashing!' } ]

    describe 'idempotence', ->

      it 'should be safe to overuse', ->
        v = shapely 1
        assert v is (shapely shapely shapely v)


describe 'combinators', ->

  describe '#opt', ->

    it 'should successfully nullify invalid items', ->

      v1 = k.opt p.number
      v2 = shapely [v1, v1, v1]
      v3 = shapely foo: v1, bar: v1

      assert (v1 'nope') is undefined

      ok v2, [1, 'foo', 2], [1, undefined, 2]

      ok v3, { foo: 'foo', bar: 7 }, { bar: 7 }

  describe '#any', ->

    it 'should try harder', ->

      v1 = k.any p.number, p.string
      v2 = shapely [v1, v1]

      ok v1, 3
      ok v1, 'x'
      ok v2, [3, 'x']

      nok v1, {}
      nok v1, false
      nok v2, [3, false]

  describe '#all', ->

    it 'should be nasty', ->

      gt = prim.satisfy '> 1', (x) -> x > 1
      lt = prim.satisfy '< 3', (x) -> x < 3
      v  = k.all gt, lt

      ok v, 2

      nok v, 1
      nok v, 3

  describe '#arrayOf', ->

    it 'should... be an array-of.', ->

      v = k.arrayOf k.any 'x', 'y', 'z'

      ok v, ['x', 'z']
      ok v, ['y', 'y']

      nok v, ['x', 'k', 'y']


describe 'context preservation', ->

  yes1 = prim.satisfy 'any' , (x) -> @push x ; true
  yes2 = prim.ensure  'any' , (x) -> @push x ; x
  nope = prim.satisfy 'none', (x) -> @push x ; false

  tracing = (final_trace, block) ->

    trace = []
    block.call trace
    assert.deepEqual trace, final_trace

  it 'persists at low level', ->

    tracing ['x', 'y'], ->
      yes1.call @, 'x'
      yes2.call @, 'y'

  it 'persists at literal level', ->

    tracing [3, 2, 1, 11, 12], ->

      v1 = shapely [yes1, yes2, yes1]
      v2 = shapely a: yes1, b: yes2

      v1.call @, [3, 2, 1]
      v2.call @, a: 11, b: 12

  it 'persists across arrays', ->

    tracing [1, 2, 3], ->

      ( k.arrayOf yes1 ).call @, [1, 2, 3]

  it 'persists across combinators', ->

    tracing ['a', 'a', 'a', 'a', 'a', 'a'], ->

      v1 = k.all yes1, yes2, yes1
      v2 = k.any nope, nope, yes1, yes2
      v3 = k.opt k.all v1, v2

      v3.call @, 'a'

  it 'is settable', ->

    trace = []

    v1 = k.all (k.any nope, yes1), yes2
    v2 = shapely
      a: v1
      b: k.ctx trace, v1

    v2.call [], a: 1, b: 2
    assert.deepEqual trace, [2, 2, 2]


describe 'complex cases', ->

  { any, all, opt, arrayOf } = k
  { number } = p

  it 'works, 1', ->

    v = shapely
      a: opt number
      b: arrayOf [number]
      c: all(number, (x) -> x + 5)

    ok v, { a:  1 , b: [[7]], c: 1 }, { a: 1, b: [[7]], c: 6 }
    ok v, { a: 'x', b: [[7]], c: 1 }, {       b: [[7]], c: 6 }
    
    nok v, { a: 1, b:   7  , c:  1  }
    nok v, { a: 1, b: [[7]], c: 'x' }

  it 'works, 2', ->

    n  = any number, (all /\d+/, parseInt)
    v2 = arrayOf ( any { x: n, y: n }, [ n, n ] )

    ok v2, [[ 1 , 2], {x:  1 , y: 2      }]
    ok v2, [[ 1 , 2], {x:  1 , y: 2, z: 3}], [[1, 2], {x: 1, y: 2}]
    ok v2, [['1', 2], {x: '1', y: 2, z: 3}], [[1, 2], {x: 1, y: 2}]

    nok v2, [[1, 2], [1]]
    nok v2, [[false, 2]]
    nok v2, [{ x: 1, z: 3 }]
    nok v2, [['x', 2]]

