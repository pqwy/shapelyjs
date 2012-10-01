
tasks   = []
request = (target, task) -> tasks.push task invoke target
finish  = -> tasks.pop()?()

run = (cmd, next) ->
  { exec } = require 'child_process'
  exec cmd, (err, stdout, stderr) ->
    throw err if err
    console.log stderr, stdout
    next?()

task 'build', 'rebuild sources', () ->
  run 'coffee --compile --output lib/ src/', finish

task 'test', 'invoke tests', ({ next }) ->
  request 'build', ->
    run 'mocha -c --compilers coffee:coffee-script', finish

