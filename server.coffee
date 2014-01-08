require "q"
winston = require "winston"
engine = require "engine.io"


logger = new winston.Logger({
    transports: [
      new winston.transports.Console(colorize:true, timestamp:true, level:"debug")
    ]
})

exports.startServer = (port, path, callback) ->
  #   #http://www.senchalabs.org/connect/
  connect = require 'connect'
  send = require('send')
  app = connect()
    .use(connect.logger('dev'))
    .use(connect.static(path))
    .use (req, res, next) ->
      # console.log req
      #req.url: '/page/Engines',
      #req.method: 'GET',
      #req.headers :{HTTP_X_REQUESTED_WITH:..}
      # send
      # console.log url
      # next()
      send(req, path+"/index.html").pipe(res)
      # res.end 'hello world\n'
    .use (req, res, next)->
      err = new Error('Not Found')
      err.number = 7;
      err.status = 404;
      throw err;
    .use(connect.errorHandler())
  #create HTTP server based and attach connect instance to it
  http = require('http').createServer(app).listen(port)

  #attach created server to engine.io to provide correct behavior of it
  server = engine.attach(http)

  #socket (engine.io) connection handler
  server.on 'connection', (socket) ->


    #send message to just connected user
    # socket.send('hi')

    #send message to all users
    # server.clients[key].send "new user connected" for key, value of server.clients

    #TODO make function static instead of anonymous
    socket.on 'message', (message) ->
      try
        data = JSON.parse message
      catch error
        res =
          message: "error"
          data: "SyntaxError: can not parse JSON `#{message}`"
        logger.error res.data
      logger.debug(data)
      switch data.message
        when "create" then res =
          message: "created"
        when "update" then res =
          message: "updated"
        when "delete" then res =
          message: "deleted"
        when "fetch" then res =
          message: "fetched"
          label: data.label
          id: data.id
        when "subscribe" then res =
          message: "subscribed"
        when "unsubscribe" then res =
          message: "unsubscribed"
        else res =
          message: "error"
      socket.send JSON.stringify res
    # socket.on 'close', ->

  #call Callback to say brunch "server is started"
  callback()




# class DataBaseFactory
#   db: {}
#   constructor: (driver, options) ->
#     Datastore = require driver
#     @db = new Datastore
#   insert: ->
#     @db.insert.apply @db, arguments
#   find: ->
#     @db.find.apply @db, arguments

# exports.startServer = (port, path, callback) ->


#   # https://github.com/louischatriot/nedb
#   db = new DataBaseFactory 'nedb', {filename: './db', autoload: true}
#   server = http.Server(app).listen port
#   socket = new WebSocketServer server, "localhost", port
#   db.insert {a:3,b:4}, -> console.log arguments


#   console.log('Listening on port '+ port);

