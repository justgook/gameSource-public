winston = require "winston"
engine = require "engine.io"
Database = require "nedb"
connect = require "connect"
send = require "send"
{Promise} = require('es6-promise')
util = require "util"

logger = new winston.Logger
    transports: [
      new winston.transports.Console colorize:true, timestamp:true, level:"debug"
    ]


exports.startServer = (port, path, callback) ->
  #   #http://www.senchalabs.org/connect/
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
    .use do connect.errorHandler

  #create HTTP server based and attach connect instance to it
  http = require('http').createServer(app).listen(port)

  #TODO add indexes label, timespan (maybe id)
  db = new Database

  #attach created server to engine.io to provide correct behavior of it
  server = engine.attach(http)

  #socket (engine.io) connection handler
  server.on 'connection', (socket) ->

    #send message to just connected user
    # socket.send('hi')

    #send message to all users
    # server.clients[key].send JSON.stringify({"message":"new user connected"}) for key, value of server.clients

    socket.on 'message', (message) ->
      try
        data = JSON.parse message
      catch error
        res =
          message: "error"
          data: "SyntaxError: can not parse JSON `#{message}`"
        logger.error res.data
      logger.debug(data)
      promise = new Promise (resolve, reject)->
        if not data.label
          #TODO add id if is set
          reject (message: "error", data:{code: "406", status: "Not Acceptable", value: "Not Acceptable, label must be set"})
        else
          switch data.message

            when "create"
              #TODO add permission filter
              #TODO add "_" before indexes (label, timespan)
              documents = data.data
              if util.isArray documents
                for item in documents
                  item.label = data.label
                  item.timespan = Date.now() / 1000
              else
                documents.label = data.label
              db.insert documents, (error, docs)->
                if error?
                  #TODO add id if is set
                  reject message: "error", data: code: "500", status: "Database error #{error}", value: "Error on inserting data - #{document}"
                else
                  res =
                    message: "created"
                    label: data.label
                    data: docs
                  res.id = data.id if data.id
                  resolve(res)

            when "fetch"
              if data.kind? # in ["last", "since", "timespan", "all"]
                switch data.kind
                  #waiting for https://github.com/louischatriot/nedb/pull/109
                  when "last" then reject (message: "error", data: {code: "501", status: "Not Implemented", value: "Kind #{data.kind} is under construction"})
                  when "since"
                    query =
                      label: data.label
                      #TODO Add error if data.since is not set
                      timespan: $gte: Date.now() / 1000 - data.since
                    db.find query, (error, docs)->
                      if error?
                        #TODO add id if is set
                        reject (message: "error", data: {code: "500", status: "Database error #{error}", value: "Cannot get document by #{query}"})
                      else
                        res =
                          message: "fetched"
                          label: data.label
                          #TODO add total count property
                          # count: 0
                          data: docs
                        res.id = data.id if data.id
                        resolve(res)
                  when "timespan" then reject (message: "error", data: {code: "501", status: "Not Implemented", value: "Kind '#{data.kind}' is under construction"})
                    #TODO add documentation and implementation
                  when "all"
                    query = data.data
                    query.label = data.label
                    db.find query, (error, docs)->
                      if error?
                        #TODO add id if is set
                        reject (message: "error", data: {code: "500", status: "Database error #{error}", value: "Cannot get document by #{query}"})
                      else
                        res =
                          message: "fetched"
                          label: data.label
                          #TODO add total count property
                          # count: 0
                          data: docs
                        res.id = data.id if data.id
                        resolve(res)
                  # then reject (message: "error", data: {code: "501", status: "Not Implemented", value: "Kind '#{data.kind}' is under construction"})
                  #TODO add id if is set
                  else reject (message: "error", data: {code: "405", status: "Method Not Allowed", value: "Unknown kind - '#{data.kind}'"})

              #TODO add total count property
              #TODO add permission filter
              else if data.data? #data.kind is not set
                if util.isArray data.data
                  #TODO add implementation of search of array
                  reject message: "error", data: code: "501", status: "Not Implemented", value: "fetch of multi records by one request not implement yet"
                else
                  data.data.label = data.label
                  db.findOne data.data, (error, docs)->
                    if error?
                      #TODO add id if is set
                      reject (message: "error", data: {code: "500", status: "Database error #{error}", value: "Cannot get document for #{data.data}"})
                    else
                      res =
                        message: "fetched"
                        label: data.label
                        #TODO add total count property
                        # count: 0
                        data: docs
                      res.id = data.id if data.id
                      resolve(res)
              else
                #TODO add id if is set
                reject (message: "error", data:{code: "406", status: "Not Acceptable", value: "Not Acceptable, kind must be set"})

            when "update" then resolve
              #TODO add permission filter
                message: "updated"
            when "delete"
              # #TODO add permission filter
              if data.data?
                if util.isArray data.data
                  #TODO add implementation
                  reject (message: "error", data: {code: "501", status: "Not Implemented", value: "delete of multi records by one request not implement yet"})
                else
                  query = data.data
                  query.label = data.label
                  db.remove query, {multi: true}, (error, numRemoved) ->
                    if error?
                      reject (message: "error", data: {code: "500", status: "Database error #{error}", value: "Cannot delete document by #{query}"})
                    else
                      res =
                        message: "deleted"
                        label: data.label
                        count: numRemoved
                      res.id = data.id if data.id?
                      resolve(res)
              else
                #TODO add id if is set
                reject (message: "error", data:{code: "406", status: "Not Acceptable", value: "Not Acceptable, data attribute must be set"})

            when "subscribe" then resolve
              message: "subscribed"
            when "unsubscribe" then resolve
              message: "unsubscribed"
            else reject
              message: "error"
              data:
                code: "405"
                status: "Method Not Allowed"
                value: """Method "#{data.message}" Not Allowed, use one of create, update, delete, fetch, subscribe or unsubscribe"""

      promise.then \
        (res)-> #resolve
          socket.send JSON.stringify res
        ,
        (res)-> #reject
          socket.send JSON.stringify res
    # socket.on 'close', ->
      return
  #call Callback to say brunch "server is started"
  callback()