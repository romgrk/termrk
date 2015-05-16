
Q = require 'q'

{CompositeDisposable} = require 'atom'
{$$, View}            = require 'space-pen'
$                     = require 'jquery.transit'

pty        = require('pty.js')
{Terminal} = require('term.js')

Termrk         = require './termrk'
{Font, Config} = require './utils'

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
            # @div class: 'terminal'


    initialize: (serializedState) ->
        @spawnProcess()
        unless @process?
            console.error "Termrk: aborting initialization"
            return

        @time = "" + Date.now()

        @pidLabel.text @process.pid

    activated: ->
        @updateTerminalSize()
        @terminalView.focus()
        @pidLabel.addClass 'fade-out'

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

        unless @terminal?
            @setupTerminalElement()

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

    animatedShow: (cb) ->
        @animate {height: @getPanelHeight()}, 250, =>
            console.log 'showed ' + @process.pid
            cb?()

    animatedHide: (cb) ->
        @animate {height: '0'}, 250, =>
            console.log 'hidden ' + @process.pid
            cb?()

    # Private: initialize the {Terminal} (term.js)
    setupTerminalElement: ->
        @terminal = new Terminal
            cols: 80
            rows: 24
            useStyle: true
            screenKeys: true

        @terminal.open @element

        @terminalView = @find('.terminal')
        @terminalView.on 'keydown', (event) =>
            if event.which == 27
                console.log 'escape'
                @blur()
            else
                console.log 'keydown', event.which

    # Private: spy on terminal's keydown function to be abble to
    # get keystrokes
    observeTerminalKeydown: ->
        originalKeydown = @terminal.keyDown

        newKeydown = (event) ->
            console.log (event.which)
            originalKeydown()

        @terminal.keyDown = newKeydown

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

        console.log 'panel: ', width, height
        console.log 'terminal: ', cols, rows
        # console.log font
        # console.log fontWidth, fontHeight

        @terminal.resize(cols, rows)
        @process.resize(cols, rows)

    # Public: returns the parent panel {PanelView}
    getParent: ->
        return $(@parent()[0])

    getPanelHeight: ->
        console.log Termrk
        console.log require('./termrk')
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
