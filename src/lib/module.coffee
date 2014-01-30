module.exports = class Module
  filters: {}
  constructor: (config)->
    console.info "registering module \"#{@constructor.name}\""

