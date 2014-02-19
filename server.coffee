# winston = require "winston"
engine = require "engine.io"
Database = require "nedb"
connect = require "connect"
send = require "send"
{Promise} = require('es6-promise')
util = require "util"

# logger = new winston.Logger
#     transports: [
#       new winston.transports.Console colorize:true, timestamp:true, level:"debug"
#     ]

module.exports.Module = require "./src/lib/module"

module.exports.startServer = (port, path, callback) ->
  #   #http://www.senchalabs.org/connect/
  app = connect()
    # .use(connect.logger('dev'))
    .use(connect.static(path))
    .use (req, res, next) ->
      send(req, path+"/index.html").pipe(res)
    .use (req, res, next)->
      err = new Error('Not Found')
      err.number = 7
      err.status = 404
      throw err
    .use do connect.errorHandler

  #create HTTP server based and attach connect instance to it
  http = require('http').createServer(app).listen(port)

  #TODO add indexes label, timespan, !!id!!
  db = new Database
  #=====================================================================================
  #=====================================================================================
  #=====================================================================================
  #=====================================================================================
  #=====================================================================================
  #TODO mock data delme letter
  #=====================================================================================
  #=====================================================================================
  #=====================================================================================
  #=====================================================================================
  Chance = require 'chance'
  chance = new Chance()
  items = []
  for id in ["Engines", "Engines/1", "Engines/2", "World", "World/Terrains", "World/Static-items", "NPC", "NPC/biped", "Characters", "Characters/Fantasy", "Characters/Military", "Characters/Monsters", "Characters/Toon", "Characters/Armor", "Characters/Weapons", "Community", "wiki", "Tutorials", "Tools"]
    item =
      label: "page"
      timespan: chance.hammertime() / 1000
      id: id
      title: chance.sentence( words: 5 )
      author: do chance.name
      content: do chance.paragraph
    items.push item

  db.insert items, (error, docs)->
    if error
      console.log "Error on creating data"
    else
      console.log "data generated"
  #=====================================================================================
  #=====================================================================================
  #=====================================================================================
  #=====================================================================================
  #=====================================================================================
  #=====================================================================================
  #=====================================================================================

  #attach created server to engine.io to provide correct behavior of it
  server = engine.attach http


  MessageFactory = require "./src/lib/messageFactory"
  #TODO make database interface,
  #pass require to have possibility require for same point
  messageFactory = new MessageFactory require: require

  #TODO move to config
  messageFactory.use "./src/system-lock"
  messageFactory.use "./src/crud"
  #=====================================================================================

  #socket (engine.io) connection handler
  server.on 'connection', (socket) ->
    #TODO create array of users to be sure that after refresh all users will be same, ore move that behavior to some module
    #for example to `users`, that will catch all users, and update "response.client" with session-id and "response.send" with send message to correct connection
    options =
      database: db
      socket: socket
      server: server
    #send message to just connected user

    # socket.send('hi')
    #send message to all users
    # server.clients[key].send JSON.stringify({"message":"new user connected"}) for key, value of server.clients

    # process.on('uncaughtException', function(err) {
    #   console.log(err.stack);
    #   throw err;
    # });


    #TODO combine all promises creation to some function
    connectionPromise = messageFactory.parseRequest("""{"message": "open"}""", options)
    connectionPromise.then \
      (res)-> #resolve
        socket.send JSON.stringify res
      ,
      (err)-> #reject
        console.log err.stack || err
        res =
          message: "error"
          stack: (err.stack or "").split("\n").slice(1).map((v) ->"" + v + "").join("")
          value: err.message
        if err.status then res.statusCode = err.status
        if not res.statusCode or res.statusCode < 400 then res.statusCode = 500
        socket.send JSON.stringify res

    socket.on 'message', (message) ->

      promise = messageFactory.parseRequest(message, options)
      promise.then \
        (res)-> #resolve
          socket.send JSON.stringify res
        ,
        (err)-> #reject
          console.log err.stack || err
          res =
            message: "error"
            stack: (err.stack or "").split("\n").slice(1).map((v) ->"" + v + "").join("")
            value: err.message
          if err.status then res.statusCode = err.status
          if not res.statusCode or res.statusCode < 400 then res.statusCode = 500
          socket.send JSON.stringify res
      return
    #on close connection execute special event in all modules
    socket.on 'close', ->
      promise = messageFactory.parseRequest("""{"message": "close"}""", options)
      promise.then \
        (res)-> #resolve
          socket.send JSON.stringify res
        ,
        (err)-> #reject
          console.log err.stack || err
          res =
            message: "error"
            stack: (err.stack or "").split("\n").slice(1).map((v) ->"" + v + "").join("")
            value: err.message
          if err.status then res.statusCode = err.status
          if not res.statusCode or res.statusCode < 400 then res.statusCode = 500
          socket.send JSON.stringify res
      return
  #call Callback to say brunch "server is started"
  callback()