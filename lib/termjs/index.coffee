

TermjsTerminal = require './term.js'

TermjsTerminal::fixIpad = ->
    if @isIpad or @isIphone
        @constructor.fixIpad(document)

class Terminal extends TermjsTerminal

    emitter: null

    ybase: 0
    ydisp: 0

    # Cursor screen position
    x:            null
    y:            null

    cursorState:  null
    cursorHidden: null

    # unknown
    scrollTop:    null
    scrollBottom: null

    state: null
    queue: null
    convertEol: null

    # Added
    isFocused: false

    # So we can use as handling-function for focusEvent
    focus: ->
        @isFocused = true

        if @sendFocus
            @send('\x1b[I')

        @showCursor()
        return true

    blur: ->
        @isFocused = false

        if (@sendFocus)
            @send('\x1b[O')

        @hideCursor()
        return true

    blink: ->
        @cursorState ^= 1
        @refresh @y, @y

    showCursor: ->
        @cursorState = 1
        @refresh @y, @y

        return if @_blink?
        
        @_blink = =>
            unless @isFocused
                clearInterval @_blink
            else
                @blink()
        setInterval @_blink, 500

    hideCursor: ->
        clearInterval @_blink if @_blink?
        @_blink = null
        @cursorState = 0
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

    # Public: create the terminal-element in the `parent` element
    open: (parent) ->
        self = this

        @parent = parent || @parent

        if !@parent
            throw new Error('Terminal requires a parent element.')

        # Grab global elements.
        @context  = @parent.ownerDocument.defaultView
        @document = @parent.ownerDocument
        @body     = @document.getElementsByTagName('body')[0]

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

        @startBlink()

        # Bind to DOM events related
        # to focus and paste behavior.
        # on(@element, 'focus', ->
        #     self.focus()
        #     if (self.isIpad || self.isIphone) {
        #         Terminal._textarea.focus()
        #     }
        # )

        # @bindMouse()

        if (Terminal.brokenBold == null)
            Terminal.brokenBold = isBoldBroken(@document)

        # @emit('open')
        setTimeout( ->
            self.element.focus()
        , 100)

        @addTabindexToChildren()

    # Public: ...
    resize: (width, height) ->
        return if width < 80
        super(width, height)

        @addTabindexToChildren()

    refresh: (args...) ->

        if @rows > @element.children.length
            lastChild = @children.pop()
            lastChild.remove()

        super(args...)

    # resize: (width, height) ->
    #     width = 1 if width < 1
    #     height = 1 if height < 1
    #
    #     # # resize cols
    #     j = @cols
    #     if j < width
    #         ch = [@defAttr, ' '] # # does xterm use the default attr?
    #         i = @lines.length
    #         while (i--)
    #             while (@lines[i].length < width)
    #                 @lines[i].push(ch)
    #     else if (j > width)
    #         i = @lines.length
    #         while (i--)
    #             while (@lines[i].length > width)
    #                 @lines[i].pop()
    #
    #     @setupStops(j)
    #     @cols = width
    #
    #     # # resize rows
    #     j = @rows
    #     if (j < height)
    #         el = @element
    #         while (j++ < height)
    #             if (@lines.length < height + @ybase)
    #                 @lines.push(@blankLine())
    #             if (@children.length < height)
    #                 line = @document.createElement('div')
    #                 el.appendChild(line)
    #                 @children.push(line)
    #     else if (j > height)
    #
    #         diff = @rows - height
    #         console.log @rows, height, diff
    #         console.log @children, @element.children
    #         # for k in [0..diff - 1]
    #             # el = @children.unshift()
    #             # @element.children[0].remove()
    #             # el?.parentNode?.removeChild(el)
    #         while (j-- > height)
    #             if (@children.length > height)
    #                 el = @children.shift()
    #                 console.log j, 'el', el
    #                 if (!el)
    #                     continue
    #                 else
    #                     el.parentNode.removeChild(el)
    #
    #     @rows = height
    #
    #     # # make sure the cursor stays on screen
    #     if (@y >= height)
    #         @y = height - 1
    #     if (@x >= width)
    #         @x = width - 1
    #
    #     @scrollTop = 0
    #     @scrollBottom = @rows - 1
    #
    #     @refresh(0, @rows - 1)
    #
    #     # # it's a real nightmare trying
    #     # # to resize the original
    #     # # screen buffer. just set it
    #     # # to null for now.
    #     @normal = null

module.exports = Terminal
