AutoCompleteView = require('lib/AutoComplete')
class SearchView extends Backbone.View
  el: "#search"
  events:
    "keyup input": "startTaping"
    "submit": "submit"
  initialize: ->
    @listenTo @model, "change:query", @renderResults
    # @listenTo @model, "change:query", @renderAutocomplete

    Plugin = Backbone.Model.extend
      label: -> @get "name"
    PluginCollection = Backbone.Collection.extend
      model: Plugin
    plugins = new PluginCollection [
      name:"aaa"
    ,
      name:"bbb"
    ,
      name:"bbb1"
    ,
      name:"bbb2"
    ,
      name:"bbb3"
    ,
      name:"bbb4"
    ]
    new AutoCompleteView({
      input: @$el.find "input" # your input field
      model: plugins # your collection
      wait:0
      minKeywordLength:1
    }).render();
    # @$el.find("input").val("dadas")
  startTaping: (e)->
    @model.set "query": e.target.value if e.target.value.length > 3
    return
  # renderAutocomplete:->

  renderResults: (query)->
     console.log "uraaa"
  submit: (e)->
    e.preventDefault()
    e.stopPropagation()
    return false
class SearchModel extends Backbone.Model

class Application extends Backbone.View
  initialize: ->
    new SearchView model: new SearchModel

ready = require "lib/ready"
ready ->
 app = new Application
