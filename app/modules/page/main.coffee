class PageModel extends Backbone.Model
  defaluts:
    title: "title"
    author: "author"
    content: "content"

class PageCollection extends Backbone.Collection
  model: PageModel
  url: 'page'
  initialize: ->
    @on "error", (model, error, options)->
      #forward error to global scope, to be able catch that with other modules
      Backbone.trigger("message:error", error)

class PageView extends Backbone.View
  template: require "./template"
  initialize: ->
    @collection = new PageCollection
  showPage: (pageId)->
    if not @collection.get pageId
      @requestPage pageId
    else
      @render @collection.get pageId
  requestPage: (pageId)->
    model = @collection.add id:pageId
    model.fetch(url: @collection.url, success: @render)
  render: (page)=>
    #TODO find better way, to be able set loading state add/or some animation to it..
    @regions.content.el.innerHTML = @template page.toJSON()

class PageRoute extends Backbone.SubRoute
  routes:
    "": "firstPage"
    "*page": (pageId)-> @view.showPage pageId
  constructor: ->
    super
    @view = new PageView
  firstPage: ->
    @navigate "wiki", true

module.exports = (configs)->
  #add data for collection
  # configs.collection ?= new PageCollection
  if not configs.regions?.content?
    throw Error """Region "content" must be set for module Page"""
  route = new PageRoute configs.route_prefix or "page"
  route.view.regions = configs.regions
