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
    @listenTo Backbone, "message:error", @addError
    @listenTo @collection, "add", @renderAdd
  renderAdd: (model, collection, options)->
    @$el.append @template model.toJSON()
  addError: (err)->
    console.log err
    data =
      type: "error"
      title: "Error"
      content: "unknown error"
    if err instanceof Error
      data.content = err.message
    @collection.add data
    return
module.exports = (configs)->
  configs.collection ?= new NotificationCollection
  new NotificationView configs