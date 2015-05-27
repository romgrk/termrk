
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
    kmSubscriptions: null

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
            'core:paste': => @model.paste()
            'termrk:insert-filename': =>
                @model.write(atom.workspace.getActiveTextEditor().getURI())
            'termrk:abort-keybinding': (e) -> e.abortKeyBinding()

    # Private: initialize the {Terminal} (term.js)
    setupTerminalElement: ->
        @terminal = new Terminal
            cols: 400
            rows: 24
            screenKeys: true
        @terminal.open @element
        @terminalView = @find('.terminal')

        @updateFont()

    # Private: attach listeners
    attachListeners: ->
        add = => @subscriptions.add

        @input.addEventListener 'keydown', @keydown.bind(@), true
        @input.addEventListener 'keypress', @terminal.keyPress.bind(@terminal)
        @input.addEventListener 'focus', => @terminal.focus()
        @input.addEventListener 'blur', => @terminal.blur()
        add => @input.removeAllListeners()

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

        console.log $(window).on 'resize', =>
            @updateTerminalSize()

    attachKeymapListeners: ->
        @kmSubscriptions = new CompositeDisposable
        @kmSubscriptions.add atom.keymaps.onDidPartiallyMatchBindings (event) ->
            return unless event?
            for binding in event.partiallyMatchedBindings
                # if /^termrk:insert/.test binding.command
                if /^termrk:/.test binding.command
                    return
                    # console.log binding.keystrokes, binding.command
        @kmSubscriptions.add atom.keymaps.onDidFailToMatchBinding (event) ->
            return
            # console.log event.keystrokes, 'nomatch'
        @kmSubscriptions.add atom.keymaps.onDidMatchBinding (event) ->
            return
            # console.log event.keystrokes, 'match', event.binding.command

    ###
    Section: event listeners
    ###

    # Private: callback
    keydown: (event) =>
        atom.keymaps.handleKeyboardEvent(event)

        if event.defaultPrevented
            event.stopImmediatePropagation()
            return false
        else
            allow = @terminal.keyDown.call(@terminal, event)
            return allow

    keypress: (event) ->
        if @isInsertVarMode
            @_keypressEvent = event

    terminalMousewheel: (event) =>
        deltaY  = event.wheelDeltaY
        deltaY /= 120
        deltaY *= -1

        @terminal.scrollDisp(deltaY)

    # Public: called after this terminal view has been activated
    activated: ->
        @updateTerminalSize()
        @focus()
        @attachKeymapListeners() unless @kmSubscriptions?
        @pidLabel.addClass 'fade-out'

    # Public: called after this terminal view has been deactivated
    deactivated: ->
        return unless document.activeElement is @input
        console.log @kmSubscriptions
        @kmSubscriptions.dispose() if @kmSubscriptions?
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
    updateTerminalSize: ->
        parent = @getParent()
        width  = parent.width()
        height = parent.height()

        font       = @terminalView.css('font')
        fontWidth  = Font.getWidth("a", font)
        fontHeight = @find('.terminal > div:first-of-type').height()
        # fontHeight = Font.getHeight("a", font)

        cols = Math.floor(width / fontWidth)
        rows = Math.floor(height / fontHeight)

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
