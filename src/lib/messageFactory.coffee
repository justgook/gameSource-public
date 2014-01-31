{Promise} = require('es6-promise')
util = require "util"

class FilterQueues
  constructor: ->
    @enterPoints = {}
  add: (event, label, callback, context)->
    if label
      @enterPoints["#{event}:#{label}"] ?= []
      # if already exist some filters in non labeled registry an it is first record
      if not @enterPoints["#{event}:#{label}"].length and @enterPoints[event]?.length
        clone =  @enterPoints[event].slice 0
        @enterPoints["#{event}:#{label}"] = clone
      @enterPoints["#{event}:#{label}"].push name: "#{context.constructor.name}:#{event}:#{label}", callback: callback, context: context
    else
      # push to execution array new event if it is non-labeled
      @enterPoints[event] ?= []
      newMember =
        name: "#{context.constructor.name}:#{event}:#{label}"
        callback: callback
        context: context
      for item in Object.keys(@enterPoints) when item.indexOf(event) is 0
        @enterPoints[item].push newMember
    return yes

  remove: (event, label, callback, context)->
    throw Error "FilterQueues.remove not implemented"

  _execNext = (queue, index, args)->
    index++
    return yes if not item = queue[index]
    args.push ->
        _execNext(queue, index, args)
        return
    item.callback.apply item.contex, args
    return yes

  exec: (event, label, args)->
    key = if label then "#{event}:#{label}" else event
    queue = @enterPoints[key] or @enterPoints[event]
    item = queue?[0]
    return yes if not item
    # if not item
    #   err = Error "No module found for request \"#{event}:#{label}\""
    #   #"""Method "#{request.body.message}" Not Allowed, use one of create, update, delete, fetch, subscribe or unsubscribe"""
    #   err.status = 405
    #   throw err
    args.push -> _execNext(queue, 0, args)
    item.callback.apply item.contex, args
    return yes


module.exports = class MessageFactory
  constructor: (config)->
    @db = config.database
    @require = config.require

    @filterQueues = new FilterQueues
    @beforeQueues = new FilterQueues
    @afterQueues = new FilterQueues

  _delegateFilterSplitter = /^(\S+)\s*(.*)$/
  _allowedEvents = ["open", "close", "create", "fetch", "update", "delete", "subscribe", "unsubscribe"]
  _result = (object, property) ->
    if object
      value = object[property]
      (if typeof value is 'function' then object[property]() else value)

  parseFilters: (module, propname, pushTo)->
    filters = module[propname or "filters"]
    #FROM backbone delegateEvents
    return this unless filters or (filters = _result(this, "filters"))
    for key, method of filters
      if typeof method is "string" then method = module[method]
      # if not method then continue
      #TODO add error for development env!
      continue unless method and typeof method is "function"
      {1: eventName, 2: label} = key.match(_delegateFilterSplitter)
      continue if eventName not in _allowedEvents
      @[pushTo or "filterQueues"].add eventName, label, method, module
    return yes

  #register module for later use
  use: (moduleName, options)=>
    if typeof moduleName is "string"
      moduleClass = @require(moduleName)
      module = new moduleClass options
    else
      module = new moduleName(options)
    #TODO add callback for wait until module is inited .. (database init, API check, login into service...)
    @parseFilters module
    @parseFilters module, "before", "beforeQueues"
    @parseFilters module, "after", "afterQueues"

  execFilters: (request, response)->
    #TODO add timeout - based on module
    @beforeQueues.exec request.body.message, request.body.label, [request]
    @filterQueues.exec request.body.message, request.body.label, [request, response]
    @afterQueues.exec request.body.message, request.body.label, [response]
  parseRequest: (message)-> #(message, socket, resolve, reject)->
    promise = new Promise (resolve, reject)=>
      try
        request =
          body: JSON.parse message
          database: @db
      catch error
        res =
          message: "error"
          data: "SyntaxError: can not parse JSON `#{message}`"
        reject(res)
      response =
        end: resolve
      if not request.body.label
        #TODO add id if is set
        reject (message: "error", data:{code: "406", status: "Not Acceptable", value: "Not Acceptable, label must be set"})
      else
        #TODO wrap with error handler
        #TODO add id if is set
        @execFilters request, response
    return promise