Module = module.parent.exports.Module
{Promise} = require('es6-promise')


module.exports = class CRUD extends Module
  filters:
    # "fetch employees": "fetchPage"
    "fetch": "fetch"
    "create": "create"
    "update": "update"
    "delete": "delete"
    subscribe: -> next(message: "subscribed")
    unsubscribe:-> next(message: "unsubscribed")
  # constructor: (config)->
  #   super
  create: (request, response)->
    documents = request.body.data
    if Array.isArray documents
      for item in documents
        item.label = request.body.label
        item.timespan = Date.now() / 1000
    else
      documents.label = request.body.label
    request.database.insert documents, (error, docs)->
      if error?
        throw Error "Error on inserting data - #{document}"
      else
        res =
          message: "created"
          label: request.body.label
          data: docs
        res.id = request.body.id if request.body.id
        response.end(res)
    return

  fetch: (request, response)->
    #TODO split it to sub-methods
    if request.body.kind? # in ["last", "since", "timespan", "all"]
      switch request.body.kind
        #for kind "last", you can send a `count` and `page` field
        when "last"
          if not request.body.count
            err = Error "Not Acceptable, for kind \"last\" must be set attribute count"
            err.status = "406"
            throw err
          if not parseInt request.body.count, 10
            err = Error "Not Acceptable, attribute count must be integer"
            err.status = "406"
            throw err
          request.body.count = parseInt request.body.count, 10
          if 0 > request.body.count
            err = Error "Not Acceptable, attribute count must greater than 0"
            err.status = "406"
            throw err
          request.body.page ?= 1
          query =
            label: request.body.label
          request.database.find(query).sort({ timespan: -1 }).skip((request.body.page - 1) * request.body.count).limit(request.body.count).exec (error, docs)->
            if error?
              #TODO add id if is set
              throw Error "Cannot get document by #{query}, with error #{error}"
            else if not docs
              res =
                message: "error"
                data:
                  code: "404"
                  status: "Not Found"
                  value: "The server has not found anything matching the Request"
              res.id = request.body.id if request.body.id
              throw Error res
            else
              res =
                message: "fetched"
                label: request.body.label
                #TODO add total count property
                # count: 0
                data: docs
              res.id = request.body.id if request.body.id
              response.end(res)
        when "since"
          query =
            label: request.body.label
            #TODO Add error if request.body.since is not set
            timespan: $gte: Date.now() / 1000 - request.body.since
          request.database.find query, (error, docs)->
            if error?
              #TODO add id if is set
              throw Error (message: "error", data: {code: "500", status: "Database error #{error}", value: "Cannot get document by #{query}"})
            else if not docs
              res =
                message: "error"
                data:
                  code: "404"
                  status: "Not Found"
                  value: "The server has not found anything matching the Request"
              res.id = request.body.id if request.body.id
              throw Error res
            else
              res =
                message: "fetched"
                label: request.body.label
                #TODO add total count property
                # count: 0
                data: docs
              res.id = request.body.id if request.body.id
              response.end(res)
        when "timespan" then throw Error (message: "error", data: {code: "501", status: "Not Implemented", value: "Kind '#{request.body.kind}' is under construction"})
          #TODO add documentation and implementation
        when "all"
          query = request.body.data
          query.label = request.body.label
          request.database.find query, (error, docs)->
            if error?
              #TODO add id if is set
              throw Error "Cannot get document by #{query}, with error #{error}"
            else if not docs
              res =
                message: "error"
                data:
                  code: "404"
                  status: "Not Found"
                  value: "The server has not found anything matching the Request"
              res.id = request.body.id if request.body.id
              throw Error res
            else
              res =
                message: "fetched"
                label: request.body.label
                #TODO add total count property
                # count: 0
                data: docs
              res.id = request.body.id if request.body.id
              response.end(res)
        # then throw Error (message: "error", data: {code: "501", status: "Not Implemented", value: "Kind '#{request.body.kind}' is under construction"})
        #TODO add id if is set
        else throw Error (message: "error", data: {code: "405", status: "Method Not Allowed", value: "Unknown kind - '#{request.body.kind}'"})
    #TODO add total count property
    else if request.body.data? #request.body.kind is not set
      if Array.isArray request.body.data
        #TODO add implementation of search of array
        throw Error message: "error", data: code: "501", status: "Not Implemented", value: "fetch of multi records by one request not implement yet"
      else
        request.body.data.label = request.body.label
        request.database.findOne request.body.data, (error, doc)->
          if error?
            throw Error "Cannot get document by  #{request.body.data}, with error #{error}"
          else if not doc
            res =
              message: "error"
              data:
                code: "404"
                status: "Not Found"
                value: "The server has not found anything matching the Request"
            res.id = request.body.id if request.body.id
            throw Error res
          else
            delete doc._id
            res =
              message: "fetched"
              label: request.body.label
              data: doc
            res.id = request.body.id if request.body.id
            response.end(res)
    else
      #TODO add id if is set
      throw Error (message: "error", data:{code: "406", status: "Not Acceptable", value: "Not Acceptable, kind must be set"})
    return

  delete: (request, response)->
    #TODO split it to sub-methods (deleteOne, deleteMeny)
    if request.body.data?
      if Array.isArray request.body.data
        promiseArray = []
        for item in request.body.data
          query = item
          query.label = request.body.label
          promiseArray.push new Promise (reslove, reject)=>
            request.database.remove query, {multi: true}, (error, numRemoved) ->
              if error?
                throw Error (message: "error", data: {code: "500", status: "Database error #{error}", value: "Cannot delete document by #{query}"})
              else
                res =
                  message: "deleted"
                  label: request.body.label
                  count: numRemoved
                res.id = request.body.id if request.body.id?
                reslove(res)
        #TODO cancat all messeges in one!
        Promise.all(promiseArray).then response.end, (err)-> throw err
      else
        query = request.body.data
        query.label = request.body.label
        request.database.remove query, {multi: true}, (error, numRemoved) ->
          if error?
            throw Error (message: "error", data: {code: "500", status: "Database error #{error}", value: "Cannot delete document by #{query}"})
          else
            res =
              message: "deleted"
              label: request.body.label
              count: numRemoved
            res.id = request.body.id if request.body.id?
            response.end(res)
    else
      #TODO add id if is set
      throw Error (message: "error", data:{code: "406", status: "Not Acceptable", value: "Not Acceptable, data attribute must be set"})
    return

  update: (req, res, next)-> next()
  subscribe: -> next(message: "subscribed")
  unsubscribe:-> next(message: "unsubscribed")