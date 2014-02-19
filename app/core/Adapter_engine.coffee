module.exports = ->
  @socket = eio "ws://localhost"
  waitingForResponse = {}
  waitingForResponseTimeOut = 3000
  # @socket.on "error"
  @socket.on "message", (message)->
    response = JSON.parse message
    switch
      #Messages without request-id - just push data from server by subscribe, or some other server behavior
      when not response.id?
        if response.message is "error"
          err = Error response.value
          delete response.message
          for key, val of response
            err[key] = val
          Backbone.trigger("message:error", err)
        else
          Backbone.trigger("message:#{response.message}", response)
      #Messages with request-id - answer to some application request
      when waitingForResponse[response.id]?
        ##############################################################
        #debug information
        # Backbone.trigger("message:#{response.message}", response.data)
        ##############################################################
        if response.message is "error"
          console.log response
          waitingForResponse[response.id][1] response.data #trigger reject/fail on request
        else
          waitingForResponse[response.id][0] response.data #trigger resolve/success on request
        delete waitingForResponse[response.id]

  # // Map from CRUD to socket messages for our `Backbone.sync` implementation.
  methodMap =
    "create": "create"
    "update": "update"
    "delete": "delete"
    "read":   "fetch"
    "subscribe" : "subscribe"
    "unsubscribe": "unsubscribe"

  Backbone.sync = (method, model, options)=>
    params =
      "message": methodMap[method] #TODO create switch
      "label": options.url or _.result(model, "url") #TODO remove starting slash if is so
      "id": _.uniqueId("fetch") #To be able to match server responses to requests, an additional `id` field can be included in the message.
    if not params.label
      throw Error """A "url" property or function must be specified"""
    #Ensure that we have the appropriate request data.
    #TODO need to check for all CRUD behaviors
    params.data = (options.attrs or model.toJSON(options)) #if not options.data? and model and (method is "create" or method is "update" or method is "patch")


    timerHolder = null
    #TODO add support for browsers that do not support Promise as native

    promise = new Promise (resolve, reject)=>
      waitingForResponse[params.id] = [resolve, reject] #push resolve and reject functions to waiting to response queue
      timerHolder = setTimeout( # if no response in some time, than trigger error
        ->
          err =  Error "Response Timeout: no answer after #{waitingForResponseTimeOut / 1000}s"
          waitingForResponse[params.id][1](err)
          delete waitingForResponse[params.id] #delete from waiting to response queue
        waitingForResponseTimeOut
      )

    @socket.send JSON.stringify params
    promise.then (-> clearTimeout timerHolder), (-> clearTimeout timerHolder)

    promise.then options.success, options.error
    promise
  return