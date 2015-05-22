
Q   = require 'q'
$   = require 'jquery.transit'
pty = require('pty.js')

{CompositeDisposable} = require 'atom'
{$$, View}            = require 'space-pen'
{Key, KeyKit}         = require 'keykit'
{Terminal}            = require 'term.js'

window.termjs = require 'term.js' if window.debug?

Utils  = require './utils'
Config = new Utils.Config('termrk')
Font   = Utils.Font

# Will be assigned to main module
Termrk = null

module.exports =
class TermrkView extends View

    # Public: {Child_process} process of the running shell
    process: null

    time: null

    terminal:     null
    terminalView: null

    @content: ->
        @div class: 'termrk', =>
            @span class: 'pid-label', outlet: 'pidLabel'
            # @div class: 'terminal' # <= created by term.js


    initialize: (serializedState) ->
        Termrk = atom.packages.getLoadedPackage('termrk')

        @setupTerminalElement()

        @spawnProcess()
        unless @process?
            console.error "Termrk: aborting initialization"
            return

        @time = "" + Date.now()

        @pidLabel.text @process.pid

    # Public: called after this terminal view has been activated
    activated: ->
        @updateTerminalSize()
        @terminalView.focus()
        @pidLabel.addClass 'fade-out'

    # Public: called after this terminal view has been deactivated
    deactivated: ->
        @pidLabel.removeClass 'fade-out'
        @terminalView.blur()

    # Public: spawns the shell process
    spawnProcess: ->
        shell = process.env.SHELL || process.env.TERM || 'sh'
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
            return

        @process.on 'data', (data) =>
            @terminal.write data

        @process.on 'exit', (code, signal) =>
            console.log "Termrk process: exit(%i) and signal %s",
                code, signal
            delete @process
            @terminal.write('Process terminated. Restarting.')
            @spawnProcess()

        @terminal.on 'data', (data) =>
            @process.write(data)

        return

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

    # Private: initialize the {Terminal} (term.js)
    setupTerminalElement: ->

        # Clear term.js style injection.
        if Terminal.insertStyle?
            Terminal.insertStyle = () -> return

        @terminal = new Terminal
            cols: 80
            rows: 24
            useStyle: true
            screenKeys: true

        @terminal.open @element
        @terminalView = @find('.terminal')

        @observeTerminalKeydown()

    # Private: spy on terminal's keyEvent function to be abble to
    # get keystrokes
    observeTerminalKeydown: ->
        # @originalTerminalKeydown = @terminal.keyDown.bind(@terminal)
        @terminal.originalKeyDown  = @terminal.keyDown
        @terminal.originalKeyPress = @terminal.keyPress

        @terminal.keyDown  = @onTerminalKeyEvent.bind(@)
        @terminal.keyPress = @onTerminalKeyEvent.bind(@)

    # Private: called whenever a key is pressed on the terminal, before
    # the terminal receives it
    onTerminalKeyEvent: (event) =>
        Termrk = require('./termrk')

        keystroke = KeyKit.fromKBEvent(event).toString()
        unfocusKeystroke = Config.get('unfocusKeystroke')

        msg = 'termrk:key '
        msg +=  keystroke + '\t' + event.type

        isKeybinding = false

        switch keystroke
            when unfocusKeystroke # escape by default
                # @dispatchCommand('hide')
                msg += '(hide)'
                isKeybinding = true
                return
            when 'ctrl-space'
                # @dispatchCommand('create-terminal')
                msg += '(create)'
                isKeybinding = true
                return
            when 'ctrl-escape'
                msg += '(esc)'
                event.ctrlKey = false
            when 'ctrl-tab'
                # @dispatchCommand('activate-next-terminal')
                msg += '(next)'
                isKeybinding = true
                return
            when 'ctrl-shift-tab'
                # @dispatchCommand('activate-previous-terminal')
                msg += '(previous)'
                isKeybinding = true
                return

        cancelled = not if isKeybinding
            true
        else if event.type is 'keypress'
            @terminal.originalKeyPress(event)
        else if event.type is 'keydown'
            @terminal.originalKeyDown(event)

        @terminal.element.focus()

        if window.debug?
            console.log msg, 'cc?', cancelled

        return (not cancelled)

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
            console.log atom.keymap.findKeyBindings(target:@terminal.element)
            console.log 'panel: ', width, height
            console.log 'terminal: ', cols, rows

        @terminal.resize(cols, rows)
        @process.resize(cols, rows)

    # Public: returns the parent panel {PanelView}
    getParent: ->
        return $(@parent()[0])

    getPanelHeight: ->
        return require('./termrk').getPanelHeight()

    # Public: returns the PID of the running process
    getPID: ->
        @process.pid

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
