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
  initializeCommunication:->
    @socket = eio('ws://localhost');
ready = require "core/ready"

ready ->
  app = new Application
