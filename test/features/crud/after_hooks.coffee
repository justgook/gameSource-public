myAfterHooks = ->
  @After (callback) ->
    for item in @protocol.mockCreated
      query = JSON.stringify
        message: "delete"
        label: item.label
        data: item.data
      @protocol.send query
      @protocol.waitForResponse
        .then ->
          return # TODO need to find way how to remove that
        .then callback, callback.fail


module.exports = myAfterHooks;