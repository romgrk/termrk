
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

    # Private: initialize the {Terminal} (term.js)
    setupTerminalElement: ->
        @terminal = new Terminal
            cols: 400
            rows: 24
            screenKeys: true
        @terminal.open @element
        @terminal.on 'data', (data) => @model.write(data)

        @terminalView = @find('.terminal')

    # Private: attach listeners
    attachListeners: ->
        @input.addEventListener 'keydown', @keydownListener.bind(@), true
        @input.addEventListener 'keypress', @terminal.keyPress.bind(@terminal)

        @input.addEventListener 'focus', =>
            @terminal.focus()
            return true
        @input.addEventListener 'blur', =>
            @terminal.blur()
            return true

        @terminal.element.addEventListener 'focus', =>
            @input.focus()

        @model.onDidStartProcess (shellName) =>
            @updateTerminalSize()
            @terminal.write("\x1b[31mProcess started: #{shellName}\x1b[m\r\n")
        @model.onDidExitProcess (code, signal) =>
            @terminal.write('\x1b[31mProcess terminated.\x1b[m\r\n')
        @model.onDidReceiveData (data) =>
            @terminal.write data

    ###
    Section: event listeners
    ###

    # Private: callback
    keydownListener: (event) =>
        atom.keymaps.handleKeyboardEvent(event)

        if event.defaultPrevented
            event.stopImmediatePropagation()
            return false
        else
            allow = @terminal.keyDown.call(@terminal, event)
            return allow

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

    # Public: animate height to 0px.
    animatedShow: (cb) ->
        @animate {height: @getPanelHeight()}, 250, ->
            cb?()

    # Public: animate height to fill the container.
    animatedHide: (cb) ->
        return if @hidding
        @hidding = true
        @animate {height: '0'}, 250, =>
            @hidding = false
            cb?()

    # Public: update the terminal cols/rows based on the panel size
    updateTerminalSize: ->
        parent = @getParent()
        width  = parent.width()
        height = @getPanelHeight()
        console.log width, height

        font       = @terminalView.css('font')
        fontWidth  = Font.getWidth("a", font)
        fontHeight = Font.getHeight("a", font)

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
        @updateTerminalSize()

    # Public: get the actual untoggled height
    getPanelHeight: ->
        return require('./termrk').getPanelHeight()

    # Public:
    focus: ->
        @input.focus()

    # Public:
    blur: ->
        @input.blur()

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
        @model.destroy()
        @element.remove()
        @subscriptions.dispose()

    getElement: ->
        @element

    getParent: ->
        $(@parent()[0])
