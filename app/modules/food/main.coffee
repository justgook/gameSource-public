# columns = [
#   {
#     name: "name"
#     label: "Name"
#     cell: "string"
#   }
#   {
#     name: "water"
#     label: "Water"
#     cell: "string"
#   }
#   {
#     name: "proteins"
#     label: "Proteins"
#     cell: "string"
#   }
#   {
#     name: "fats"
#     label: "Fats"
#     cell: "string"
#   }
#   {
#     name: "carbohydrates"
#     label: "Carbohydrates"
#     cell: "string"
#   }
#   {
#     name: "kcal"
#     label: "Kcal"
#     cell: "string"
#   }
# ]

# Territory = Backbone.Model.extend {}
# class Territories extends Backbone.Collection
#   model: Territory

# territories = new Territories()

# $.ajax("/example.json")
# .then (a)->
#   territories.set a
#   console.log a

# grid = new Backgrid.Grid
#   columns: columns
#   collection: territories

# class ProductModel extends Backbone.Model
#   defaluts:
#     name:"" #Продукт
#     water:"" #Вода
#     proteins:"" #Белки
#     fats:"" #Жиры
#     carbohydrates:"" # Углеводы
#     kcal:"" #ккал

Calendar = require "core/Calendar"

console.log (new Calendar).generate "week"


class MealModel extends Backbone.Model
    schema: {
        title: 'Text',
        author: { type: 'Object', subSchema: {
            id: 'Number',
            name: { type: 'Object', subSchema: {
                first: 'Text',
                last: 'Text'
            }}
        }}
    }
# class MealView extends Backbone.View
meal = new MealModel

form = new Backbone.Form model: meal, fields: ['title', 'author.id', 'author.name.last']

class FoodView extends Backbone.View
  # template: require "./template"
  # titleTemplate: require "./title"
  setApp: (@app)->
  initialize: ->
    # @collection = new PageCollection
  showPage: (pageId)->
    do @render
    # if not @collection.get pageId
    #   @requestPage pageId
    # else
    #   @render @collection.get pageId
  requestPage: (pageId)->
    model = @collection.add id:pageId
    model.fetch(url: @collection.url, success: @render)
  render: (page)=>
    #TODO find better way, to be able set loading state add/or some animation to it..

    @app.setMainEl (new Calendar).renderYear()[0]
    # @app.setMainEl form.render().el
    # @app.setHelperEl @template page.toJSON()

class FoodRoute extends Backbone.SubRoute
  routes:
    "": "firstPage"
    "*page": (pageId)-> @view.showPage pageId
  constructor: ->
    super
    @view = new FoodView
  firstPage: ->
    @navigate "wiki", true

module.exports = (configs)->
  if not configs.app?
    throw Error """app must provide setMainEl method"""
  route = new FoodRoute configs.route_prefix or "food"
  route.view.setApp configs.app
