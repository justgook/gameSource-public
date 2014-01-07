class PageModel extends Backbone.Model
  url: @id

class PageCollection extends Backbone.Collection
  model: PageModel
  url: '/page'

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
      @renderPage page
  requestPage: (page)->
    @collection.fetch data:id:page
  renderPage: (page)->
    console.trace arguments
    @view.render page
  renderError: (errorType, errorObj, pageId)->
    console.log "fail"
exports = new PageRoute "page"
