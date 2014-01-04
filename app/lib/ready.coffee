# https://gist.github.com/Contra/2477661
# DOM ready
ready = (fn) ->
  fire = ->
    unless ready.fired
      ready.fired = true
      fn()

  return fire() if document.readyState is "complete"

  # Mozilla, Opera, WebKit
  if document.addEventListener
    document.addEventListener "DOMContentLoaded", fire, false
    window.addEventListener "load", fire, false

  # IE
  else if document.attachEvent
    check = ->
      try
        document.documentElement.doScroll "left"
      catch e
        setTimeout check, 1
        return
      fire()
    document.attachEvent "onreadystatechange", fire
    window.attachEvent "onload", fire
    check() if document.documentElement and document.documentElement.doScroll and !window.frameElement

module.exports = ready