class Application extends Backbone.View
  el: "body"
  regions:{}
  initialize: ->
    @initializeRegions()
    @initializeCommunication()
    # require("modules/search/main") regions: @regions
    require("modules/page/main") app: setMainEl: @setMainEl, setHelperEl: @setHelperEl
    require("modules/food/main") app: setMainEl: @setMainEl, setHelperEl: @setHelperEl
    # require("modules/notification/main") el: "#notification"
    @initializeRoute()
  initializeRegions: ->
    #move to template / theme config or create base classes
    @regions =
      main:
        front: @el.querySelector "main>.front"
        back: @el.querySelector "main>.back"
      helper:
        front: @el.querySelector "section>.front"
        back: @el.querySelector "section>.back"
  mainFlipFront: true
  #TODO move to template
  setMainEl: (el)=>
    #TODO add remove trigger
    if @mainFlipFront
      current = @regions.main.front
      @mainFlipFront = false
    else
      current = @regions.main.back
      @mainFlipFront = true
    if typeof el is "string"
      current.innerHTML = el
    else if el.nodeType is 1
      current.innerHTML = ""
      current.appendChild el
    else
      throw Error "Element must be string or DomNode"
    current.parentNode.classList.toggle "front"

  #TODO move to template
  helperFlipFront: true
  setHelperEl: (el)=>
    if @helperFlipFront
      current = @regions.helper.front
      @helperFlipFront = false
    else
      current = @regions.helper.back
      @helperFlipFront = true
    if typeof el is "string"
      current.innerHTML = el
    else
      current.innerHTML = ""
      current.appndChild el
    current.parentNode.classList.toggle "front"

  initializeRoute: ->
    @el.addEventListener "click", (e) ->
      node = e.target if e.target.tagName is "A"
      node = e.target.parentNode if e.target.parentNode.tagName is "A"
      if node
        e.preventDefault()
        fragment = node.getAttribute "href"
        fragment = fragment.slice(1) if fragment?.charAt(0) == "/"
        Backbone.history.navigate fragment, true
    Backbone.history.start pushState: true

  initializeCommunication: ->
    require("core/Adapter_engine")()

ready = require "core/ready"
ready ->
  app = new Application
