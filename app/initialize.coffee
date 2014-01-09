class Application extends Backbone.View
  el: "body"
  regions:{}
  initialize: ->
    @initializeRegions()
    @initializeCommunication()
    require "modules/search/main"
    require "modules/page/main"
    @initializeRoute()
  initializeRegions: ->
    @regions =
      header:
        el: @el.querySelector "header"
        # template: require "templates/menu"
      content:
        el: @el.querySelector "#content"
        # template: "templates/page"
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
    @socket.on "message", (message)->
      response = JSON.parse message
      switch
        #Messages without request-id - just push data from server by subscribe, or some other server behavior
        #TODO find better way how automatically update application (collection / models)
        when not response.id? then Backbone.trigger("data:#{response.message}", response.data)

        #Messages with request-id - answer to some application request
        when waitingForResponse[response.id]?
          waitingForResponse[response.id][0] response.data #trigger resolve/success on request
          delete waitingForResponse[response.id]
          """
            on success get model auto-subscribe to it to get all updates for it
            on delete/destroy model, unsubscribe from getting updates
          """

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
        "label": _.result(model, "url") or throw new Error """A "url" property or function must be specified""" if !options.url #TODO remove starting slash if is so
        "id": _.uniqueId("fetch") #To be able to match server responses to requests, an additional `id` field can be included in the message.


      #Ensure that we have the appropriate request data.
      #TODO need to check for all CRUD behaviors
      params.data = (options.attrs or model.toJSON(options)) #if not options.data? and model and (method is "create" or method is "update" or method is "patch")
      @socket.send JSON.stringify params

      timerHolder = null
      #TODO add support for browsers that do not support Promise as native
      promise = new Promise (resolve, reject)=>
        waitingForResponse[data.id] = [resolve, reject] #push resolve and reject functions to waiting to response queue
        timerHolder = setTimeout( # if no response in some time, than trigger error
          ->
            delete waitingForResponse[data.id] #delete from waiting to response queue
            reject Error "Response Timeout: no answer after #{waitingForResponseTimeOut / 1000}s"
          waitingForResponseTimeOut
        )

      promise.then (-> clearTimeout timerHolder), (-> clearTimeout timerHolder)
      promise.then options.success, options.error

ready = require "core/ready"
ready ->
  app = new Application
