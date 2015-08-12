
_   = require 'underscore-plus'
$   = require 'jquery.transit'
pty = require 'pty.js'

{Emitter}             = require 'atom'
{CompositeDisposable} = require 'atom'
{$$, View}            = require 'space-pen'
{Key, KeyKit}         = require 'keykit'

Termrk      = require './termrk'

Terminal    = require './termjs-fix'
TermrkModel = require './termrk-model'

Config = require './config'
Utils  = require './utils'
Font   = Utils.Font
Keymap = Utils.Keymap
Paths  = Utils.Paths

module.exports =
class TermrkView extends View

    ###
    Section: static
    ###

    @instances: new Set()

    @addInstance: (termrkView) ->
        termrkView.time = String(Date.now())
        @instances.add(termrkView)

    @removeInstance: (termrkView) ->
        @instances.remove(termrkView)

    @fontChanged: =>
        @instances.forEach (instance) ->
            instance.updateFont.call(instance)
            instance.updateTerminalSize.call(instance)

    ###
    Section: instance
    ###

    model:              null
    emitter:            null
    subscriptions:      null
    modelSubscriptions: null

    # Public: creation time. Used as index {String}
    time: null

    # Private: {term.js:Terminal}
    termjs:     null

    isInsertVarMode: false

    @content: ->
        @div class: 'termrk', =>
            @input class: 'input-keylistener'
            # @div class: 'terminal', => # <= created by term.js

    ###
    Section: Events
    ###

    onDidResize: (callback) ->
        @emitter.on 'resize', callback

    ###
    Section: init/setup
    ###

    # TODO use HTMLElement, to get an 'attached' event
    initialize: (@options={}) ->
        TermrkView.addInstance this
        @options.name ?= 'xterm-256color'

        @emitter            = new Emitter
        @subscriptions      = new CompositeDisposable
        @modelSubscriptions = new CompositeDisposable

        @input = @element.querySelector 'input'

        @termjs = new Terminal
            cols: @options.cols
            rows: @options.rows
            name: @options.name
        @termjs.open @element

        @attachListeners()
        @updateFont()

    # TODO document options
    start: (options) ->
        _.extend @options, options

        @updateFont()

        @model = new TermrkModel @options
        @model.spawnProcess(@options)

        @attachModelListeners()

    # Private: add event listener and create disposable
    addEventListener: (element, event, callback) ->
        element.addEventListener event, callback
        @subscriptions.add dispose: ->
            element.removeEventListener event, callback

    # Private: attach listeners
    attachListeners: ->
        @addEventListener @input, 'keydown', (e) => @inputKeydown(e)
        @addEventListener @input, 'keypress', (e) => @termjs.keyPress(e)
        @addEventListener @input, 'focus', => @termjs.focus()
        @addEventListener @input, 'blur', => @termjs.blur()

        @addEventListener @termjs.element, 'focus', => @input.focus()
        @addEventListener @termjs.element, 'mousewheel', @terminalMousewheel.bind(@)

        @addEventListener window, 'resize', => @updateTerminalSize()

    # Private: attach model listeners
    attachModelListeners: ->
        add = (d) => @modelSubscriptions.add d

        add @model.onDidStartProcess (shellName) =>
            @termjs.write("\x1b[31mProcess started: #{@options.shell}\x1b[m\r\n")

        add @model.onDidExitProcess (code, signal) =>
            @processExit(code, signal)

        add @model.onDidReceiveData (data) => @termjs.write data

        dataListener = (data) => @model.write(data)
        @termjs.on 'data', dataListener
        add dispose: =>
            @termjs.off 'data', dataListener

    ###
    Section: event listeners
    ###

    # Private: callback
    inputKeydown: (event) =>
        atom.keymaps.handleKeyboardEvent(event)

        if event.defaultPrevented
            event.stopImmediatePropagation()
            return false
        else
            allow = @termjs.keyDown.call(@termjs, event)
            return allow

    # Private: mouseWheel event callback
    terminalMousewheel: (event) =>
        deltaY = event.wheelDeltaY

        # OS X
        if process.platform is 'darwin'

            # ZachR0: change this as you like

            if event.type is 'DOMMouseScroll'
                deltaY += if event.detail < 0 then -1 else 1
            else
                deltaY += if event.wheelDeltaY > 0 then -1 else 1
            deltaY *= -1

            amount = deltaY

        # Linux/Win32
        else
            return if deltaY is 0 or deltaY is NaN
            # reduce to 1 or -1 and inverse direction
            amount = -1 * (deltaY / Math.abs(deltaY))

        @termjs.scrollDisp(amount)

    # Private: insert character from passed event.
    triggerKeypress: (event) =>
        keystroke = KeyKit.fromKBEvent event.originalEvent
        if keystroke.char?
            keypressEvent = KeyKit.createKBEvent 'keypress', keystroke
            @input.dispatchEvent keypressEvent

    # Private: pty exit callback
    processExit: (event) ->
        @termjs.write("\x1b[31mProcess terminated.\x1b[m\r\n")
        @modelSubscriptions.dispose()

    # Private: called after this terminal view has been activated
    activated: ->
        @updateTerminalSize()
        @focus()

    # Private: called after this terminal view has been deactivated
    deactivated: ->
        return unless document.activeElement is @input
        @blur()

    ###
    Section: display/render
    ###

    # Public: animate height to fill the container.
    animatedShow: (cb) ->
        @stop()
        @animate {height: '100%'}, 250, =>
            @updateTerminalSize()
            cb?()

    # Public: animate height to 0px.
    animatedHide: (cb) ->
        @stop()
        @animate {height: '0'}, 250, ->
            cb?()

    # Public: update the terminal cols/rows based on the element size
    updateTerminalSize: =>
        width  = @width()
        height = @height()

        [cols, rows] = @calculateTerminalDimensions(width, height)

        return if cols < 15 or rows < 5
        # FIXME avoid terminal being resized when panel is showing
        return if cols == 100

        @termjs.resize cols, rows
        @model.resize  cols, rows

        @emitter.emit 'resize', {cols, rows}

    # Public: set font from config
    updateFont: =>
        @find('.terminal').css
            'font-size':   Config.get('fontSize')
            'font-family': Config.get('fontFamily')

        computedFont = @find('.terminal').css('font')
        @css 'font', computedFont

        @updateTerminalSize()

    # Public: returns [cols, rows] for the given width and height
    calculateTerminalDimensions: (width, height) ->
        [fontWidth, fontHeight] = @getCharDimensions()

        cols = Math.floor(width / fontWidth)
        rows = Math.floor(height / fontHeight)

        return [cols, rows]

    # Public: get terminal element font
    getCharDimensions: ->
        font   = @find('.terminal').css 'font'
        width  = Utils.getFontWidth("a", font)
        height  = @find('.terminal > div:first-of-type').height()
        return [width, height]

    # Public: focus terminal
    focus: ->
        # @termjs.focus()
        @input.focus()
        return true

    # Public: blur terminal
    blur: ->
        # @termjs.blur()
        @input.blur()
        return true

    ###
    Section: actions
    ###

    write: (text) ->
        @model.write text

    ###
    Section: helpers/utils
    ###

    # Private: registers commands
    registerCommands: (target, commands) ->
        @subscriptions.add atom.commands.add target, commands

    # Public: returns an object that can be retrieved when package is activated
    serialize: ->

    # Tear down any state and detach
    destroy: ->
        @modelSubscriptions.dispose()
        @subscriptions.dispose()
        @model.destroy()
        @element.remove()

    getElement: ->
        @element

    getParent: ->
        $(@parent()[0])

    getModel: ->
        @model
