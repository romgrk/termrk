
_   = require 'underscore-plus'
$   = require 'jquery.transit'
pty = require 'pty.js'

{Emitter}             = require 'atom'
{CompositeDisposable} = require 'atom'
clipboard             = require 'clipboard'
{$$, View}            = require 'space-pen'

Termrk      = require './termrk'

Terminal    = require './termjs-fix'
TermrkModel = require './termrk-model'

Config = require './config'
Utils  = require './utils'
Font   = Utils.Font
Keymap = Utils.Keymap
Paths  = Utils.Paths

debug = (m...) ->
    return unless window.debug == true
    console.debug(m...)

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

    @colorsChanged: ({oldValue, newValue}) =>
        return unless newValue.length is 8 or newValue.length is 16 or
            newValue.length is 10 or newValue.length is 18
        @instances.forEach (instance) ->
            instance.updateColors(oldValue, newValue)

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

    onDidExitProcess: (callback) ->
        @emitter.on 'exit', callback

    ###
    Section: init/setup
    ###

    # Private: setup
    # TODO use HTMLElement, so we can get an 'attached' event
    initialize: (@options={}) ->
        TermrkView.addInstance this
        @options.name ?= 'xterm-256color'

        @emitter            = new Emitter
        @subscriptions      = new CompositeDisposable

        @input = @element.querySelector 'input'

        @termjs = new Terminal
            cols: @options.cols
            rows: @options.rows
            name: @options.name
            colors: Config.terminalColors
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

    # Private: add event listener and add the created disposable
    # to the @subscriptions list
    addEventListener: (element, event, callback) ->
        element.addEventListener event, callback
        @subscriptions.add dispose: ->
            element.removeEventListener event, callback

    # Private: attach listeners
    attachListeners: ->
        @addEventListener @input, 'focus', => @termjs.focus()
        @addEventListener @input, 'blur', => @termjs.blur()
        @addEventListener @input, 'paste', (e) => @inputPaste(e)
        @addEventListener @input, 'keydown', (e) => @inputKeydown(e)
        @addEventListener @input, 'keypress', (e) => @termjs.keyPress(e)

        @addEventListener @termjs.element, 'focus', => @input.focus()
        @addEventListener @termjs.element, 'mousewheel', @terminalMousewheel.bind(@)

        @addEventListener window, 'resize', => @updateTerminalSize()

    # Private: attach model listeners
    attachModelListeners: ->
        @modelSubscriptions = new CompositeDisposable
        add = (d) => @modelSubscriptions.add d

        add @model.onDidStartProcess (shellName) =>
            @termjs.write("\x1b[31mProcess started: #{@options.shell}\x1b[m\r\n")

        add @model.onDidExitProcess (code, signal) =>
            @processExit(code, signal)

        add @model.onDidReceiveData (data) => @termjs.write data

        dataListener = (data) => @model.write(data)
        @termjs.addListener 'data', dataListener
        add dispose: =>
            @termjs.removeListener 'data', dataListener

    ###
    Section: event listeners
    ###

    # Private: callback
    inputKeydown: (event) =>
        atom.keymaps.handleKeyboardEvent(event)

        if event.defaultPrevented
            event.stopImmediatePropagation()
            debug('inputKeydown(prevented):', event)
            return false
        else if @model?
            allow = @termjs.keyDown.call(@termjs, event)
            debug('inputKeydown(allowed):', event)
            return allow
        else
            @start() if event.keyCode == 13 # enter

    # Private: input 'paste' event callback
    inputPaste: (event) =>
        if process.platform isnt 'linux' # implemented specifically for
          return                         # middle-click-paste on Xorg server
        debug('inputPaste:', event)
        @write clipboard.readText('selection')

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

    # Private: pty exit callback
    processExit: (event) ->
        @termjs.write("\x1b[31mProcess terminated.\x1b[m\r\n")

        @modelSubscriptions.dispose()
        @model.destroy()
        delete @model

        @emitter.emit 'exit', event
        if Config.restartShell
            @start()
        else
            @termjs.write("\x1b[31mPress Enter to restart \x1b[m")

    # Private: called after this terminal view has been activated
    activated: ->
        #@updateTerminalSize()
        #@focus()

    # Private: called after this terminal view has been deactivated
    deactivated: ->
        #return unless document.activeElement is @input
        #@blur()

    ###
    Section: display/render
    ###

    # Public: animate height to fill the container.
    animatedShow: (cb) ->
        @stop()
        @focus()
        @animate {height: '100%'}, 250, =>
            @updateTerminalSize()
            cb?()

    # Public: animate height to 0px.
    animatedHide: (cb) ->
        @stop()
        @blur()
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
        @model.resize  cols, rows if @model?

        @emitter.emit 'resize', {cols, rows}

    # Public: set font from config
    updateFont: =>
        @find('.terminal').css
            'font-size':   Config.get('fontSize')
            'font-family': Config.get('fontFamily')

        computedFont = @find('.terminal').css('font')
        @css 'font', computedFont

        @updateTerminalSize()

    # Public: set colors from config
    updateColors: (oldValue, newValue) =>
        # update colors array on @termjs
        length = newValue.length
        if length % 8 is 0
            @termjs.colors = newValue.concat @termjs.colors.slice(length)
        else
            @termjs.colors = newValue.slice(0, -2).concat(
                @termjs.colors.slice(length - 2, -2), newValue.slice(-2))
            @find('.terminal').css
                'background-color': newValue[length - 2]
                'color'           : newValue[length - 1]

        # refresh
        @termjs.refresh 0, @termjs.rows

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
        @model?.destroy()
        @element.remove()

    getElement: ->
        @element

    getModel: ->
        @model
