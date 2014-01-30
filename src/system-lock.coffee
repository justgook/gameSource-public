Module = module.parent.exports.Module
module.exports = class SystemLock extends Module
  filters:
    "fetch": "goNext" # remove me after test
    "fetch employees": "goNext2" # remove me after test
    # "create": "isUnLocked"
    # "update": "isUnLocked"
    # "delete": "isUnLocked"

    # "create systemLock": "unlockSystem"
    # "delete systemLock": "lockSystem"

  # constructor: (config)->
  #   super
  goNext: (req, res, next)-> console.log("sysLock:fetch"); next()
  goNext2: (req, res, next)-> console.log("sysLock:fetch:employees"); next()
  # isUnLocked: (req, res, next)-> next()
  # unlockSystem: (req, res, next)-> next()
  # lockSystem: (req, res, next)-> next()
  # goNext: (next, resolve, reject, clientSocket)-> next()
  # isUnLocked: (next, resolve, reject, clientSocket)-> reject(message: "error", data:{code: "403", status: "Forbidden", value: "data change is locked"}) #block all request with error
  # unlockSystem: (next, resolve, reject, clientSocket)-> resolve()
  # lockSystem: (next, resolve, reject, clientSocket)-> resolve()