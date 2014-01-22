# https://gist.github.com/spmason/1670196
# http://stackoverflow.com/questions/20173242/timestamps-disappear-when-adding-the-line-number-configuration-in-node-js-winsto
# http://senecacd.wordpress.com/2013/03/18/node-js-real-time-logging-with-winston-redis-and-socket-io-p1/
# https://github.com/baryon/tracer


# winston = require("winston")
# logger = new (winston.Logger)(
#     transports: [new (winston.transports.Console)(level: "debug", colorize: 'true', 'timestamp':true)]
# )
# logger.log "info", "Dasdasd"
# zombie = require "zombie"

# colors = require('colors')
# console = require('tracer').colorConsole
#   filters:
#     warn : colors.yellow



configs =
  port: process.env.npm_package_config_port or "8080"
  host: process.env.npm_package_config_host or "localhost"
  process: process.env.npm_package_config_process


# childProcess = require("child_process")
# ls = childProcess.exec(configs.process, (error, stdout, stderr) ->
#   if error
#     console.log error.stack
#     console.log "Error code: " + error.code
#     console.log "Signal received: " + error.signal
#   console.log "Child Process STDOUT: " + stdout
#   console.log "Child Process STDERR: " + stderr
# )
# ls.on "exit", (code) ->
#   console.log "Child process exited with exit code " + code
# setTimeout ->
#   ls.kill('SIGHUP')
# ,1000


# .kill('SIGHUP')
{Promise} = require('es6-promise')
World = (callback) ->
  arrayOfPromises = []
  # zombie.debug = true
  # @browser = new zombie( # this.browser will be available in step definitions
  #   debug: true
  #   runScripts: false
  # )
  # @visit = (url, callback) ->
  #   @browser.visit url, callback
  # constructor: ->
    # console.log "YKGH"

  @protocol =
    socket: require('engine.io-client')('ws://localhost:3333') #TODO add items from configuration file, to be able change host!
    socketMessages: []
    waitForResponse: Promise.resolve()
    mockCreated: []
    waitForResponseResolve: ->

  @protocol.send = (message, callback)=>
    @protocol.waitForResponse = new Promise (resolve, reject)=>
      @protocol.waitForResponseResolve = resolve
    #store created mocks to letter delete
    parsed = JSON.parse message
    @protocol.mockCreated.push parsed if parsed.message is "create"
    @protocol.socket.send message, callback


  #wait till socket is connected
  arrayOfPromises.push new Promise (resolve, reject)=>
    @protocol.socket.on "error", reject
    @protocol.socket.on "open", resolve
    @protocol.socket.on "message", (message)=>
      parsed = JSON.parse message
      @protocol.socketMessages.push parsed
      @protocol.waitForResponseResolve parsed


  Promise.all(arrayOfPromises).then (->callback()), ((a)-> console.error a) # tell Cucumber we're finished and to use 'this' as the world instance
  return #fixing world context returning

exports.World = World
