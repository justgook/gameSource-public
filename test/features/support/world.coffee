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

colors = require('colors')
console = require('tracer').colorConsole
  filters:
    warn : colors.yellow


Promise = require('es6-promise').Promise
arrayOfPromises = []

World = (callback) ->
  # zombie.debug = true
  # @browser = new zombie( # this.browser will be available in step definitions
  #   debug: true
  #   runScripts: false
  # )
  # @visit = (url, callback) ->
  #   @browser.visit url, callback
  @protocol =
    socket: require('engine.io-client')('ws://localhost:3333') #TODO add items from configuration file, to be able change host!
    socketMessages: []
    waitForResponse: Promise.resolve()
    waitForResponseResolve: ->

  @protocol.send = (message, callback)=>
    @protocol.waitForResponse = new Promise (resolve, reject)=>
      @protocol.waitForResponseResolve = resolve
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
