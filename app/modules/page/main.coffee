class PageModel extends Backbone.Model
class PageCollection extends Backbone.Collection
  model: PageModel
class PageView extends Backbone.View
class PageRoute extends Backbone.SubRoute
  routes:
    "": "firstPage"
    "*page": "showPage"
  constructor: ->
    super
  firstPage: ->
    @navigate "wiki", true
  showPage: (page)->
    console.log page
exports = new PageRoute "page"
