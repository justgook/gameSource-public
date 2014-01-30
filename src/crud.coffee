Module = module.parent.exports.Module

module.exports = class CRUD extends Module
  filters:
    "fetch page": "fetchPage"
    "fetch": "fetch"
    "create": "create"
    "update": "update"
    "delete": "delete"
  # constructor: (config)->
  #   super
  create: (request, next, resolve, reject)->
    next()
    #TODO add "_" before indexes (label, timespan)
    # documents = request.data
    # if util.isArray documents
    #   for item in documents
    #     item.label = request.label
    #     item.timespan = Date.now() / 1000
    # else
    #   documents.label = request.label
    # @db.insert documents, (error, docs)->
    #   if error?
    #     #TODO add id if is set
    #     reject message: "error", data: code: "500", status: "Database error #{error}", value: "Error on inserting data - #{document}"
    #   else
    #     res =
    #       message: "created"
    #       label: request.label
    #       data: docs
    #     res.id = request.id if request.id
    #     resolve res
  fetch: (req, res, next)-> console.log(req); console.log("crud:fetch"); next()
  fetchPage: (req, res, next)-> console.log(req); console.log("crud:fetch:page"); next()
  update: (req, res, next)-> next()
  delete: (req, res, next)-> next()