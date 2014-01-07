AutoCompleteView = require('core/AutoComplete')
class SearchView extends Backbone.View
  el: "#search"
  regions:{}
  events:
    "keyup input": "startTaping"
    "submit": "submit"
  initialize: (options)->
    # console.log options
    @regions = options.regions
    @listenTo @model, "change:query", @renderResults
    @initializeAutocomplete()
    # @listenTo @model, "change:query", @renderAutocomplete
  startTaping: (e)->
    @model.set "query": e.target.value if e.target.value.length > 3
    return
  initializeAutocomplete:->
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
      wait: 0
      minKeywordLength: 0
    }).render()
  renderResults: (query)->
     console.log "uraaa"
  submit: (e)->
    e.preventDefault()
    e.stopPropagation()
    return false
class SearchModel extends Backbone.Model
exports = new SearchView model: new SearchModel