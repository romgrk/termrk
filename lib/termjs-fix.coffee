
termjs = require 'term.js'

# TODO rethink object structure
# this could be merged with the model,
# and there would be a Terminal HTMLElement

class Terminal extends termjs.Terminal

    @bindKeys: ->
        return if @_mouseListener?
        @_mouseListener = (ev) ->
            unless Terminal.focus and ev.target?
                return

            el = ev.target
            while el
                if (el is Terminal.focus.element)
                    return
                el = el.parentNode
            Terminal.focus.blur()
        document.addEventListener 'mousedown', @_mouseListener

    # Public: create the terminal-element in the `parent` element
    open: (parent) ->
        termjs.Terminal.brokenBold = false

        self = this

        @parent = parent || @parent

        if !@parent
            throw new Error('Terminal requires a parent element.')

        # Grab global elements.
        @context  = window
        @document = document
        @body     = document.getElementsByTagName('body')[0]

        # Parse user-agent strings.
        if (@context.navigator && @context.navigator.userAgent)
            @isMac = !!~@context.navigator.userAgent.indexOf('Mac')
            @isIpad = !!~@context.navigator.userAgent.indexOf('iPad')
            @isIphone = !!~@context.navigator.userAgent.indexOf('iPhone')
            @isMSIE = !!~@context.navigator.userAgent.indexOf('MSIE')

        # Create our main terminal element.
        @element = @document.createElement('div')
        @element.className = 'terminal'
        @element.style.outline = 'none'
        @element.setAttribute('tabindex', 0)

        # This allows user to set terminal style in CSS
        @colors[256] = @element.style.backgroundColor
        @colors[257] = @element.style.color

        # Create the lines for our terminal.
        @children = []
        for i in [0..@rows]
            div = @document.createElement('div')
            @element.appendChild(div)
            @children.push(div)

        @parent.appendChild(@element)

        # Draw the screen.
        @refresh(0, @rows - 1)

        # @constructor.bindKeys()
        @focus()

        # FIXME?
        setTimeout( ->
            self.element.focus()
        , 100)

    # Public: ...
    resize: (width, height) ->
        super(width, height)
        @addTabindexToChildren()

    # Public: focus handler
    focus: ->
        if @sendFocus and not @isFocused
            @send('\x1b[I')
        @isFocused = true
        @showCursor()
        return true

    # Public: blur handler
    blur: ->
        if @sendFocus and @isFocused
            @send('\x1b[O')
        @isFocused = false
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

    # Public: this allows for selection of text inside terminal
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
