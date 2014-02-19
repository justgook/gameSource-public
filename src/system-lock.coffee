Module = module.parent.exports.Module
module.exports = class SystemLock extends Module
  constructor: ->
    console.log "SYS LOCK"
    @unlockedConnections = {}
    super
  before:
    "update": "isUnLocked"
    "delete": "isUnLocked"
  filters:
    "close": "lockSystem"
    # "open": (req, res, next)-> console.log "open new connection"; next()
    "create systemLock": "unlockSystem"
    "create": "isUnLocked"
    "delete systemLock": "lockSystem"
  # constructor: (config)->
  #   super
  isUnLocked: (req, others..., next)->
    return next() if @unlockedConnections[req.client]?.unlocked
    throw Error "System is locked for #{req.body.message}"

  unlockSystem: (req, res, next)->
    if not @unlockedConnections[req.client]?
      @unlockedConnections[req.client] =
        unlocked: no
        key: Array.apply(0, Array(32)).map(->
          ((charset) ->
            charset.charAt Math.floor(Math.random() * charset.length)
          ) "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        ).join ""
      return res.end message: "created", label: "systemLock", data: "message generated #{@unlockedConnections[req.client].key}"
    else if req.body.data?.key is @unlockedConnections[req.client].key
      @unlockedConnections[req.client].unlocked = yes
      return res.end message: "created", label: "systemLock", data: "system unlocked"
    throw Error "unlockSystem BAD BAD BAD "


  lockSystem: (req, res, next)->
    delete @unlockedConnections[req.client]
    next()
