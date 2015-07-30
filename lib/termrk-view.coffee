
Q   = require 'q'
$   = require 'jquery.transit'
pty = require 'pty.js'

{Emitter}             = require 'atom'
{CompositeDisposable} = require 'atom'
{$$, View}            = require 'space-pen'
{Key, KeyKit}         = require 'keykit'

window.termjs = require 'term.js' if window.debug?

Termrk      = require './termrk'
TermrkModel = require './termrk-model'
Terminal    = require './termjs-fix'

Config = require './config'
Utils  = require './utils'
Font   = Utils.Font
Keymap = Utils.Keymap
Paths  = Utils.Paths

# Makes it more readable when callback is inline
delay = (ms, callback) -> setTimeout(callback, ms)

module.exports =
class TermrkView extends View

    ###
    Section: static
    ###

    @instances: new Set()

    @addInstance: (termrkView) ->
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

    model:         null
    emitter:       null
    subscriptions: null

    # Public: creation time. Used as index {String}
    time: null

    # Public: {pty.js:Terminal} process of the running shell
    process: null

    # Public: {term.js:Terminal} and jQ wrapper of the element
    terminal:     null
    terminalView: null

    isInsertVarMode: false

    @content: ->
        @div class: 'termrk', =>
            @span class: 'pid-label', outlet: 'pidLabel'
            @input class: 'input-keylistener'
            # @div class: 'terminal' # <= created by term.js

    ###
    Section: Events
    ###

    onDidResize: (callback) ->
        @emitter.on 'resize', callback

    ###
    Section: init/setup
    ###

    initialize: (@model) ->
        TermrkView.addInstance this
        @time  = String(Date.now())

        @model.setView this

        @emitter = new Emitter
        @subscriptions = new CompositeDisposable

        @input = @element.querySelector 'input'
        @setupTerminalElement()

        @attachListeners()

        @registerCommands '.termrk',
            'termrk:trigger-keypress': @triggerKeypress.bind(@)
            'core:paste': =>
                @model.paste()
                @focus()
            'termrk:insert-filename': =>
                content = atom.workspace.getActiveTextEditor().getURI()
                @model.write(content)

    # Private: initialize the {Terminal} (term.js)
    setupTerminalElement: ->
        @terminal = new Terminal
            cols: 400
            rows: 24
            screenKeys: false
        @terminal.open @element
        @terminalView = @find('.terminal')

        @updateFont()

    # Private: attach listeners
    attachListeners: ->
        add = (d) => @subscriptions.add d

        @input.addEventListener 'keydown', @inputKeydown.bind(@), true
        @input.addEventListener 'keypress', @terminal.keyPress.bind(@terminal)
        @input.addEventListener 'focus', => @terminal.focus()
        @input.addEventListener 'blur', => @terminal.blur()

        @terminal.element.addEventListener 'focus', =>
            @input.focus()
        @terminal.element.addEventListener 'mousewheel', @terminalMousewheel.bind(@)

        @terminal.on 'data', (data) =>
            @model.write(data)

        add @model.onDidStartProcess (shellName) =>
            @terminal.write("\x1b[31mProcess started: #{shellName}\x1b[m\r\n")
        add @model.onDidExitProcess (code, signal) =>
            @terminal.write('\x1b[31mProcess terminated.\x1b[m\r\n')
        add @model.onDidReceiveData (data) =>
            @terminal.write data

        resizeHandler = @updateTerminalSize.bind(@)
        window.addEventListener 'resize', resizeHandler
        add dispose: ->
            window.removeEventListener 'resize', resizeHandler

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
            allow = @terminal.keyDown.call(@terminal, event)
            return allow

    # Private: callback
    terminalMousewheel: (event) =>
        deltaY  = event.wheelDeltaY
        deltaY /= 120
        deltaY *= -1

        @terminal.scrollDisp(deltaY)

    # Private: insert character from passed event.
    triggerKeypress: (event) =>
        keystroke = KeyKit.fromKBEvent event.originalEvent
        if keystroke.char?
            keypressEvent = KeyKit.createKBEvent 'keypress', keystroke
            @input.dispatchEvent keypressEvent

    # Public: called after this terminal view has been activated
    activated: ->
        @updateTerminalSize()
        @focus()
        @pidLabel.addClass 'fade-out'

    # Public: called after this terminal view has been deactivated
    deactivated: ->
        return unless document.activeElement is @input
        @pidLabel.removeClass 'fade-out'
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

    # Public: update the terminal cols/rows based on the panel size
    updateTerminalSize: =>
        parent = @getParent()
        width  = parent.width()
        height = parent.height()

        font       = @terminalView.css('font')
        fontWidth  = Font.getWidth("a", font)
        fontHeight = @find('.terminal > div:first-of-type').height()
        # fontHeight = Font.getHeight("a", font)

        cols = Math.floor(width / fontWidth)
        rows = Math.floor(height / fontHeight)

        # FIXME avoid terminal being resized when panel is showing
        return if cols == 100

        @terminal.resize(cols, rows)

        @model.resize(cols, rows)

        @emitter.emit 'resize', {cols, rows}

    # Public: set font from config
    updateFont: =>
        @terminalView.css
            'font-size':   Config.get('fontSize')
            'font-family': Config.get('fontFamily')

    # Public: get the actual untoggled height
    getPanelHeight: ->
        return require('./termrk').getPanelHeight()

    # Public:
    focus: ->
        @input.focus()
        return true

    # Public:
    blur: ->
        @input.blur()
        return true

    ###
    Section: helpers/utils
    ###

    # Private: registers commands
    registerCommands: (target, commands) ->
        @subscriptions.add atom.commands.add target, commands

    # Private: add subscription
    subscribe: (disposable) ->
        @subscriptions.add disposable

    # Public: returns an object that can be retrieved when package is activated
    serialize: ->

    # Tear down any state and detach
    destroy: ->
        @model.destroy()
        @element.remove()
        @subscriptions.dispose()

    getElement: ->
        @element

    getParent: ->
        $(@parent()[0])

    getModel: ->
        @model
