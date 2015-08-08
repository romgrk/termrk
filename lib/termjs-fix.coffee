
TermjsTerminal = require 'term.js'

# TODO rethink object structure
# this could be merged with the model,
# and there would be a Terminal HTMLElement

class Terminal extends TermjsTerminal

    # TODO emitter: null

    ybase: 0
    ydisp: 0

    # Cursor screen position
    x:            null
    y:            null

    # blink-on or blink-off (1 or 0)
    cursorState:  null
    cursorHidden: null

    # unknown
    scrollTop:    null
    scrollBottom: null

    state: null
    queue: null
    convertEol: null

    # TODO better detection of focus
    isFocused: false

    # Public: create the terminal-element
    open: (parent) ->
        super(parent)
        @emit('open')

    # Public: focus handler
    focus: ->
        @isFocused = true

        if @sendFocus
            @send('\x1b[I')

        @showCursor()
        return true

    # Public: blur handler
    blur: ->
        @isFocused = false

        if (@sendFocus)
            @send('\x1b[O')

        @hideCursor()
        return true

    # Private: show cursor and start blink
    showCursor: ->
        @cursorState = 1
        @refresh @y, @y
        @startBlinkInterval()

    # Private: stop blink and hide cursor
    hideCursor: ->
        @clearBlinkInterval()
        @cursorState = 0
        @refresh @y, @y

    # Private: start blinking
    startBlinkInterval: ->
        @cursorBlink = on
        if @_blinkInterval?
            clearInterval @_blinkInterval
        @_blinkInterval = setInterval @blink.bind(@), 500

    # Private: stop cursor blink interval
    clearBlinkInterval: ->
        @cursorBlink = off
        if @_blinkInterval?
            clearInterval @_blinkInterval
            @_blinkInterval = null

    # Private: blink beat
    blink: ->
        if @cursorBlink is off
            @clearBlinkInterval()
            return
        # TODO
        # if @cursorHidden is true
        #     return
        # else
        @cursorState ^= 1
        @refresh @y, @y

    resize: (cols, rows) ->
        super(cols, rows)
        @addTabindexToChildren()

    # Private: this allows for selection of text inside terminal
    addTabindexToChildren: ->
        clickFunction = ->
            selection = window.getSelection()
            unless selection? and selection.type is 'Range'
                @parentElement.focus()

        mouseUpFunction = ->
            @focus()

        for child in @element.children
            child.tabIndex    = 0
            child.onmousedown = -> true
            child.onmouseup   = mouseUpFunction
            child.onclick     = clickFunction

module.exports = Terminal
