{Promise} = require('es6-promise')
util = require "util"

class FilterQueues
  enterPoints: {}
  add: (event, label, callback, context)->
    if label
      @enterPoints["#{event}:#{label}"] ?= []
      # if already exist some filters in non labeled registry an it is first record
      if not @enterPoints["#{event}:#{label}"].length and @enterPoints[event]?.length
        clone = []
        for item, index in @enterPoints[event]
          newItem =
            name: item.name
            callback: item.callback
            context: item.context
            next: if index isnt (clone.length - 1) then clone[index + 1] else null
          clone.push newItem
        @enterPoints["#{event}:#{label}"] = clone
      if (length = @enterPoints["#{event}:#{label}"].push name: "#{context.constructor.name}:#{event}:#{label}", callback: callback, context: context, next: null) > 1
        @enterPoints["#{event}:#{label}"][length - 2].next = @enterPoints["#{event}:#{label}"][length - 1]
    else
      # push to execution array new event if it is non-labeled
      @enterPoints[event] ?= []
      for item in Object.keys(@enterPoints) when item.indexOf(event) is 0
        if (length = @enterPoints[item].push name: "#{context.constructor.name}:#{event}:#{label}", callback: callback, context: context, next: null) > 1
          @enterPoints[item][length - 2].next = @enterPoints[item][length - 1]

    return yes

  remove: (event, label, callback, context)->
    throw Error "FilterQueues.remove not implemented"
  _execNext= (queueMember, request, resolve, last)=>
    queue = queueMember.next
    console.log "#{queueMember.name} -> #{queue.name}"
    goToNext =
      if queue.next is null then last
      else =>
        _execNext(queue, request, resolve, last)
        return
    queue.callback.apply queue.contex, [request, resolve, goToNext]
    # queues.callback.apply queues.contex, [request, resolve, @_execNext]
  exec: (event, label, request, resolve, reject, next)->
    key = if label then "#{event}:#{label}" else event
    queue = @enterPoints[key]?[0]
    return do next if not queue
      #TODO uncomment error after CRUD move to module
      # throw Error "no module found for request #{event}:#{label}"
    console.log @enterPoints[key].length
    console.log "============#{queue.name} -> #{queue?.next.name}=============="
    queue.callback.apply queue.contex, [request, resolve, => _execNext(queue, request, resolve, next)]

    # queues.callback.apply queues.contex, [request, resolve, @_execNext] #TODO add more info, like user(socket), htmlServer..

module.exports = class MessageFactory
  constructor: (config)->
    @db = config.database
    @require = config.require

  filterQueues: new FilterQueues

  _delegateFilterSplitter = /^(\S+)\s*(.*)$/
  _allowedEvents = ["open", "close", "create", "fetch", "update", "delete", "subscribe", "unsubscribe"]
  _result = (object, property) ->
    if object
      value = object[property]
      (if typeof value is 'function' then object[property]() else value)

  addFilters: (module)->
    filters = module.filters
    #FROM backbone delegateEvents
    return this unless filters or (filters = _result(this, "filters"))
    for key, method of filters
      if typeof method is "string" then method = module[method]
      # if not method then continue
      #TODO add error for development env!
      continue unless method and typeof method is "function"
      {1: eventName, 2: label} = key.match(_delegateFilterSplitter)
      continue if eventName not in _allowedEvents
      @filterQueues.add eventName, label, method, module
    return yes

  #register module for later use
  use: (moduleName, options)=>
    if typeof moduleName is "string"
      moduleClass = @require(moduleName)
      module = new moduleClass options
    else
      module = new moduleName(options)
    #TODO add callback for wait until module is inited .. (database init, API check, login into service...)
    @addFilters module
    # console.log @filterQueues.enterPoints
    # console.log "-------------------------"

  execFilters: (request, next, resolve, reject)->
    #TODO add timeout - based on module
    @filterQueues.exec request.message, request.label, request, resolve, reject, next

  parseRequest: (message)-> #(message, socket, resolve, reject)->
    return new Promise (resolve, reject)=>
      try
        request = JSON.parse message
      catch error
        res =
          message: "error"
          data: "SyntaxError: can not parse JSON `#{message}`"
        reject(res)
      if not request.label
        #TODO add id if is set
        reject (message: "error", data:{code: "406", status: "Not Acceptable", value: "Not Acceptable, label must be set"})
      else
        #TODO wrap with error handler
        @execFilters(request, (-> console.log("fire next From MessageFactory")), resolve, reject)

        switch request.message
          when "create"
            #TODO add "_" before indexes (label, timespan)
            documents = request.data
            if util.isArray documents
              for item in documents
                item.label = request.label
                item.timespan = Date.now() / 1000
            else
              documents.label = request.label
            @db.insert documents, (error, docs)->
              if error?
                #TODO add id if is set
                reject message: "error", data: code: "500", status: "Database error #{error}", value: "Error on inserting data - #{document}"
              else
                res =
                  message: "created"
                  label: request.label
                  data: docs
                res.id = request.id if request.id
                resolve(res)

          when "fetch"
            if request.kind? # in ["last", "since", "timespan", "all"]
              switch request.kind
                #for kind "last", you can send a `count` and `page` field
                when "last"
                  if not request.count
                    return reject(message: "error", data:{code: "406", status: "Not Acceptable", value: "Not Acceptable, for kind \"last\" must be set attribute count"})
                  if not parseInt request.count, 10
                    return reject(message: "error", data:{code: "406", status: "Not Acceptable", value: "Not Acceptable, attribute count must be integer"})
                  request.count = parseInt request.count, 10
                  if 0 > request.count
                    return reject(message: "error", data:{code: "406", status: "Not Acceptable", value: "Not Acceptable, attribute count must greater than 0"})
                  request.page ?= 1
                  query =
                    label: request.label
                  @db.find(query).sort({ timespan: -1 }).skip((request.page - 1) * request.count).limit(request.count).exec (error, docs)->
                    if error?
                      #TODO add id if is set
                      reject (message: "error", data: {code: "500", status: "Database error #{error}", value: "Cannot get document by #{query}"})
                    else if not docs
                      res =
                        message: "error"
                        data:
                          code: "404"
                          status: "Not Found"
                          value: "The server has not found anything matching the Request"
                      res.id = request.id if request.id
                      reject res
                    else
                      res =
                        message: "fetched"
                        label: request.label
                        #TODO add total count property
                        # count: 0
                        data: docs
                      res.id = request.id if request.id
                      resolve(res)
                when "since"
                  query =
                    label: request.label
                    #TODO Add error if request.since is not set
                    timespan: $gte: Date.now() / 1000 - request.since
                  @db.find query, (error, docs)->
                    if error?
                      #TODO add id if is set
                      reject (message: "error", data: {code: "500", status: "Database error #{error}", value: "Cannot get document by #{query}"})
                    else if not docs
                      res =
                        message: "error"
                        data:
                          code: "404"
                          status: "Not Found"
                          value: "The server has not found anything matching the Request"
                      res.id = request.id if request.id
                      reject res
                    else
                      res =
                        message: "fetched"
                        label: request.label
                        #TODO add total count property
                        # count: 0
                        data: docs
                      res.id = request.id if request.id
                      resolve(res)
                when "timespan" then reject (message: "error", data: {code: "501", status: "Not Implemented", value: "Kind '#{request.kind}' is under construction"})
                  #TODO add documentation and implementation
                when "all"
                  query = request.data
                  query.label = request.label
                  @db.find query, (error, docs)->
                    if error?
                      #TODO add id if is set
                      reject (message: "error", data: {code: "500", status: "Database error #{error}", value: "Cannot get document by #{query}"})
                    else if not docs
                      res =
                        message: "error"
                        data:
                          code: "404"
                          status: "Not Found"
                          value: "The server has not found anything matching the Request"
                      res.id = request.id if request.id
                      reject res
                    else
                      res =
                        message: "fetched"
                        label: request.label
                        #TODO add total count property
                        # count: 0
                        data: docs
                      res.id = request.id if request.id
                      resolve(res)
                # then reject (message: "error", data: {code: "501", status: "Not Implemented", value: "Kind '#{request.kind}' is under construction"})
                #TODO add id if is set
                else reject (message: "error", data: {code: "405", status: "Method Not Allowed", value: "Unknown kind - '#{request.kind}'"})
            #TODO add total count property
            else if request.data? #request.kind is not set
              if util.isArray request.data
                #TODO add implementation of search of array
                reject message: "error", data: code: "501", status: "Not Implemented", value: "fetch of multi records by one request not implement yet"
              else
                request.data.label = request.label
                @db.findOne request.data, (error, doc)->
                  if error?
                    #TODO add id if is set
                    reject (message: "error", data: {code: "500", status: "Database error #{error}", value: "Cannot get document for #{request.data}"})
                  else if not doc
                    res =
                      message: "error"
                      data:
                        code: "404"
                        status: "Not Found"
                        value: "The server has not found anything matching the Request"
                    res.id = request.id if request.id
                    reject res
                  else
                    delete doc._id
                    res =
                      message: "fetched"
                      label: request.label
                      data: doc
                    res.id = request.id if request.id
                    resolve(res)
            else
              #TODO add id if is set
              reject (message: "error", data:{code: "406", status: "Not Acceptable", value: "Not Acceptable, kind must be set"})

          when "update" then resolve
            #TODO add permission filter
              message: "updated"
          when "delete"
            # #TODO add permission filter
            if request.data?
              if util.isArray request.data
                promiseArray = []
                for item in request.data
                  query = item
                  query.label = request.label
                  promiseArray.push new Promise (resolve, reject)=>
                    @db.remove query, {multi: true}, (error, numRemoved) ->
                      if error?
                        reject (message: "error", data: {code: "500", status: "Database error #{error}", value: "Cannot delete document by #{query}"})
                      else
                        res =
                          message: "deleted"
                          label: request.label
                          count: numRemoved
                        res.id = request.id if request.id?
                        resolve(res)
                #TODO cancat all messeges in one!
                Promise.all(promiseArray).then resolve, reject
              else
                query = request.data
                query.label = request.label
                @db.remove query, {multi: true}, (error, numRemoved) ->
                  if error?
                    reject (message: "error", data: {code: "500", status: "Database error #{error}", value: "Cannot delete document by #{query}"})
                  else
                    res =
                      message: "deleted"
                      label: request.label
                      count: numRemoved
                    res.id = request.id if request.id?
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
              value: """Method "#{request.message}" Not Allowed, use one of create, update, delete, fetch, subscribe or unsubscribe"""
