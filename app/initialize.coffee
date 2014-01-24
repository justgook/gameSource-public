class Application extends Backbone.View
  el: "body"
  regions:{}
  initialize: ->
    @initializeRegions()
    @initializeCommunication()
    require("modules/search/main") regions: @regions
    require("modules/page/main") regions: @regions
    require("modules/notification/main") el: "#notification"
    @initializeRoute()
  initializeRegions: ->
    @regions =
      header:
        el: @el.querySelector "header"
      content:
        el: @el.querySelector "#content"
      notification:
        el: @el.querySelector "#notification"

  initializeRoute: ->
    @el.addEventListener "click", (e) ->
      node = e.target if e.target.tagName is "A"
      node = e.target.parentNode if e.target.parentNode.tagName is "A"
      if node
        e.preventDefault()
        fragment = node.getAttribute "href"
        fragment = fragment.slice(1) if fragment?.charAt(0) == "/"
        Backbone.history.navigate fragment, true
    Backbone.history.start({pushState: true})
  initializeCommunication: ->
    #TODO move to adapter
    @socket = eio "ws://localhost"
    waitingForResponse = {}
    waitingForResponseTimeOut = 3000
    # @socket.on "error"
    @socket.on "message", (message)->
      response = JSON.parse message
      switch
        #Messages without request-id - just push data from server by subscribe, or some other server behavior
        when not response.id? then Backbone.trigger("message:#{response.message}", response.data)

        #Messages with request-id - answer to some application request
        when waitingForResponse[response.id]?
          ##############################################################
          #debug information
          # Backbone.trigger("message:#{response.message}", response.data)
          ##############################################################
          if response.message is "error"
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
            delete waitingForResponse[params.id] #delete from waiting to response queue
            reject Error "Response Timeout: no answer after #{waitingForResponseTimeOut / 1000}s"
          waitingForResponseTimeOut
        )

      @socket.send JSON.stringify params
      promise.then (-> clearTimeout timerHolder), (-> clearTimeout timerHolder)

      promise.then options.success, options.error
      promise

ready = require "core/ready"
ready ->
  app = new Application
