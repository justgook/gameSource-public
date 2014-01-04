# based on http://fatiherikli.github.io/backbone-autocomplete/

class AutoCompleteItemView extends Backbone.View
  tagName: "li"
  template: _.template "<a href=\"#\"><%= label %></a>"
  events:
    click: "select"
  initialize: (options)->
    @options = options
  render: ->
    @$el.html @template(label: @model.label())
    this

  select: ->
    @options.parent.hide().select @model
    false

AutoCompleteView = Backbone.View.extend
  tagName: "ul"
  className: "autocomplete"
  wait: 300
  queryParameter: "query"
  minKeywordLength: 2
  currentText: ""
  itemView: AutoCompleteItemView
  initialize: (options) ->
    _.extend this, options
    @filter = _.debounce(@filter, @wait)

  render: ->

    # disable the native auto complete functionality
    @input.attr "autocomplete", "off"
    @$el.width @input.outerWidth()
    @input.keyup(_.bind(@keyup, this)).keydown(_.bind(@keydown, this)).after @$el
    this

  keydown: (event) ->
    return @move(-1)  if event.keyCode is 38
    return @move(+1)  if event.keyCode is 40
    return @onEnter()  if event.keyCode is 13
    @hide()  if event.keyCode is 27

  keyup: ->
    keyword = @input.val()
    if @isChanged(keyword)
      if @isValid(keyword)
        @filter keyword
      else
        @hide()

  filter: (keyword) ->
    keyword = keyword.toLowerCase()
    if @model.url
      parameters = {}
      parameters[@queryParameter] = keyword
      @model.fetch
        success: ->
          @loadResult @model.models, keyword
        # .bind(this)
        data: parameters

    else
      @loadResult @model.filter((model) ->
        model.label().toLowerCase().indexOf(keyword) isnt -1
      ), keyword

  isValid: (keyword) ->
    keyword.length > @minKeywordLength

  isChanged: (keyword) ->
    @currentText isnt keyword

  move: (position) ->
    current = @$el.children(".active")
    siblings = @$el.children()
    index = current.index() + position
    if siblings.eq(index).length
      current.removeClass "active"
      siblings.eq(index).addClass "active"
    false

  onEnter: ->
    @$el.children(".active").click()
    false

  loadResult: (model, keyword) ->
    @currentText = keyword
    @show().reset()
    if model.length
      _.forEach model, @addItem, this
      @show()
    else
      @hide()

  addItem: (model) ->
    @$el.append new @itemView(
      model: model
      parent: this
    ).render().$el

  select: (model) ->
    label = model.label()
    @input.val label
    @currentText = label
    @onSelect model

  reset: ->
    @$el.empty()
    this

  hide: ->
    @$el.hide()
    this

  show: ->
    @$el.show()
    this

  # callback definitions
  onSelect: ->


module.exports = AutoCompleteView