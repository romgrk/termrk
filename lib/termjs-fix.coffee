

termjs = require('term.js')

class Terminal extends termjs.Terminal

    @insertStyle: -> return

    @bindKeys: ->
        document.addEventListener 'mousedown', (ev) ->
            unless Terminal.focus
                return
            el = ev.target || ev.srcElement
            return unless el?
            while el
                if (el is Terminal.focus.element)
                    return
                el = el.parentNode
            Terminal.focus.blur();

    focus: ->
        super()
        return true

    blur: ->
        super()
        return true

module.exports = Terminal
