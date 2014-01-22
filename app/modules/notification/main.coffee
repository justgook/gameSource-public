class NotificationModel extends Backbone.Model
  defaults:
    title: ""
    type: "info" #["error", "warning", "info"]
    content:""

class NotificationCollection extends Backbone.Collection
  model: NotificationModel

class NotificationView extends Backbone.View
  template: (data)-> """<li class="#{data.type}"><h4>#{data.title}</h4>#{data.content}</li>"""
  initialize:->
    @listenTo Backbone, "message:error", @parseError
    @listenTo @collection, "add", @renderAdd
  renderAdd: (model, collection, options)->
    @$el.append @template model.toJSON()
  parseError: ({code, status, value})->
    @collection.add content: value, title: "#{status} (#{code})"
module.exports = (configs)->
  configs.collection ?= new NotificationCollection
  new NotificationView configs