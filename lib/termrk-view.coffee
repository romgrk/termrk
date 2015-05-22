
Q   = require 'q'
$   = require 'jquery.transit'
pty = require('pty.js')

{CompositeDisposable} = require 'atom'
{$$, View}            = require 'space-pen'
{Key, KeyKit}         = require 'keykit'
Terminal              = require './termjs-fix'

window.termjs = require 'term.js' if window.debug?

Utils  = require './utils'
Config = new Utils.Config('termrk')
Font   = Utils.Font
Keymap = Utils.Keymap

# Will be assigned to main module
Termrk = null

module.exports =
class TermrkView extends View

    ###
    Section: static
    ###

    @getShell: ->
        if process.env.SHELL?
            process.env.SHELL
        else if /win/.test process.platform
            # TODO cygwin?
            process.env.TERM ? process.env.COMSPEC
        else
            'sh'

    ###
    Section: instance
    ###

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
    Section: init/setup
    ###

    initialize: (serializedState) ->
        Termrk = atom.packages.getLoadedPackage('termrk')

        @time  = String(Date.now())
        @input = @element.querySelector 'input'

        @setupTerminalElement()

        @spawnProcess()

        @attachListeners()

    # Private: starts pty.js child process
    spawnProcess: ->
        shell = Config.get 'shellCommand'
        if shell is 'auto-detect'
            shell = @constructor.getShell()

        # shell = process.env.SHELL || process.env.TERM || 'sh'
        options =
                name: 'xterm-256color'
                cols: 80
                rows: 24
                cwd: process.cwd()

        try
            @process = pty.fork(shell, [], options)
            console.log "Termrk: started process #{shell}"
            console.log "pid:#{@process.pid} and fd:#{@process.fd}"
        catch error
            console.error("Termrk: couldn't start process "
                + "#{shell} with pid:#{@process.pid}")
            console.error error
            throw error

        @process.on 'data', (data) =>
            @terminal.write data

        @process.on 'exit', (code, signal) =>
            console.log "Termrk process: exit(%i) and signal %s",
                code, signal
            delete @process
            @terminal.write('Process terminated. Restarting.')
            @spawnProcess()

        @pidLabel.text @process.pid

        return

    # Private: initialize the {Terminal} (term.js)
    setupTerminalElement: ->
        @terminal = new Terminal
            cols: 80
            rows: 24
            useStyle: true
            screenKeys: true

        @terminal.open @element
        @terminalView = @find('.terminal')
        @terminal.on 'data', (data) => @process.write(data)

    # Private: attach listeners
    attachListeners: ->
        @input.addEventListener 'keydown', @keydownListener.bind(@), true
        # document.querySelector('atom-workspace').addEventListener 'keydown',
        #     @keydownListener.bind(@)
        @input.addEventListener 'keypress', @terminal.keyPress.bind(@terminal)

        @input.addEventListener 'focus', =>
            @terminal.focus()
            console.log 'focus'
            return true
        @input.addEventListener 'blur', =>
            @terminal.blur()
            console.log 'blur'
            return true

        @terminal.element.addEventListener 'focus', =>
            @input.focus()

    ###
    Section: event listeners
    ###

    # Private: callback
    keydownListener: (event) =>
        return unless event.target is @input
        keystroke = atom.keymaps.keystrokeForKeyboardEvent(event)
        bindings  = Keymap.find target: @terminal.element, keystrokes: keystroke

        atom.keymaps.handleKeyboardEvent(event)
        if event.defaultPrevented
            console.log keystroke, 'prevented', event
            event.stopImmediatePropagation()
            return false
        else
            allow = @terminal.keyDown.call(@terminal, event)
            console.log keystroke, event.target.tagName + '.' + event.target.className,
                allow, event
            return allow

    # Public: called after this terminal view has been activated
    activated: ->
        @updateTerminalSize()
        @focus()
        @pidLabel.addClass 'fade-out'

    # Public: called after this terminal view has been deactivated
    deactivated: ->
        @pidLabel.removeClass 'fade-out'
        @blur()

    ###
    Section: display/render
    ###

    # Public: animate height to 0px.
    animatedShow: (cb) ->
        @animate {height: @getPanelHeight()}, 250, =>
            if window.debug?
                console.log 'showed ' + @process.pid
            cb?()

    # Public: animate height to fill the container.
    animatedHide: (cb) ->
        @animate {height: '0'}, 250, =>
            if window.debug?
                console.log 'hidden ' + @process.pid
            cb?()

    # Public: update the terminal cols/rows based on the panel size
    updateTerminalSize: ->
        parent = @getParent()
        width  = parent.width()
        height = @getPanelHeight()

        font       = @terminalView.css('font')
        fontWidth  = Font.getWidth("a", font)
        fontHeight = Font.getHeight("a", font)

        cols = Math.floor(width / fontWidth)
        rows = Math.floor(height / fontHeight)

        if window.debug?
            console.log 'resize terminal: ', cols, rows

        @terminal.resize(cols, rows)
        @process.resize(cols, rows)

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

    # Public: dispatches the command `name` on element
    #
    # `name` - {String} command to dispatch
    #           if `name` doesn't contains '.', 'termrk.' is prepended
    #
    # Returns nothing.
    dispatchCommand: (name) ->
        unless name.match /\./
            name = "termrk:" + name
        atom.commands.dispatch(
            @element,
            # document.querySelector('atom-workspace'),
            name)
        console.log 'termrk:dispatched ' + name

    # Public: returns an object that can be retrieved when package is activated
    serialize: ->

    # Tear down any state and detach
    destroy: ->
        @process.kill()
        @element.remove()

    getProcess: ->
        @process

    getElement: ->
        @element

    getParent: ->
        return $(@parent()[0])

    getPID: ->
        @process.pid
