

{Terminal} = require('term.js')

mouseListener = (ev) ->
    unless Terminal.focus
        return

    el = ev.target || ev.srcElement
    return unless el?

    while el
        if (el is Terminal.focus.element)
            return
        el = el.parentNode

    Terminal.focus.blur();

Terminal.insertStyle = -> return
Terminal.bindKeys    = -> document.addEventListener 'mousedown', mouseListener

module.exports = Terminal
