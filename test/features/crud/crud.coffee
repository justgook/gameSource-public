# colors = require('colors')
# console = require('tracer').colorConsole
#   filters:
#     warn : colors.yellow


expect = require('chai').expect
util = require "util"

# foo = 'bar'
# beverages = { tea: [ 'chai', 'matcha', 'oolong' ] }
crudStepDefinitions = ->
  @World = require("../support/world").World # overwrite default World constructor

  @Given /^few documents in database:$/, (table, callback)->
    #TODO filter by label!
    data = table.hashes()
    query = JSON.stringify
      message: "create"
      label: "employees"
      data: data
    @protocol.send query
    @protocol.waitForResponse
      .then ->
        return # TODO need to find way how to remove that
      .then callback, callback.fail

  @When /^when i request for a document with$/, (string, callback)->
    @protocol.send string, callback

  @Then /^I should see JSON response that contains$/, (string, callback)->
    requiredData = JSON.parse string
    @protocol.waitForResponse
      .then (message)->
        expect(message).to.have.property key, value for key, value of requiredData when key isnt "data"
        if util.isArray requiredData.data
          expect(message.data).to.have.length requiredData.data.length
          expect(message.data[index]).to.have.property key, value for key, value of item for index, item in requiredData.data
        else
          expect(message.data).to.have.property key, value for key, value of requiredData.data
        return
      .then callback, callback.fail

module.exports = crudStepDefinitions
