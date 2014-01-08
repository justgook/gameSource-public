class PageModel extends Backbone.Model
  url: @id

class PageCollection extends Backbone.Collection
  model: PageModel
  url: 'page'

class PageView extends Backbone.View
class PageRoute extends Backbone.SubRoute
  routes:
    "": "firstPage"
    "*page": "showPage"
  constructor: ->
    super
    @collection = new PageCollection
    @view = new PageView
  firstPage: ->
    @navigate "wiki", true
  showPage: (pageId)->
    if not @collection.get pageId
      @requestPage(pageId).then \
        => @renderPage(pageId)
        ,
        (xhr, errorType, errorObj)=> @renderError(errorType, errorObj, pageId)
    else
      @renderPage pageId
  requestPage: (page)->
    model = @collection.add id:page
    model.fetch {url: @collection.url}
  renderPage: (page)->
    console.log "PageRoute:renderPage"
    @view.render page
  renderError: (errorType, errorObj, pageId)->
    console.log "PageRoute:renderError"
exports = new PageRoute "page"
