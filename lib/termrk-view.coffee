
Q = require 'q'

{CompositeDisposable} = require 'atom'
{$, $$, View}         = require 'space-pen'

pty        = require('pty.js')
{Terminal} = require('term.js')

{Font} = require './utils'

module.exports =
class TermrkView extends View

    # Public: {Child_process} process of the running shell
    process: null

    @content: ->
        @div class: 'termrk', =>
            @span class: 'pid-label', outlet: 'pidLabel'
            # @div class: 'terminal'


    initialize: (serializedState) ->
        @spawnProcess()
        unless @process?
            console.error "Termrk: aborting initialization"
            return

        @time = Date.now()

        @pidLabel.text @process.pid

        @on 'keydown', (event) =>
            if event.which == 13
                console.log 'escape'
                @blur()

    activated: ->
        @updateTerminalSize()
        @pidLabel.addClass 'hidden'

    deactivated: ->
        @pidLabel.removeClass 'hidden'

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
            @spawnProcess()

        @terminal.on 'data', (data) =>
            @process.write(data)

    animatedShow: (cb) ->
        @animate {height: '400px'}, 250, =>
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

    # Public: update the terminal cols/rows based on the panel size
    updateTerminalSize: ->
        parent = @getParent()
        dimensions = [parent.width(), parent.height()]

        font       = @terminalView.css('font')
        fontWidth  = Font.getWidth("a", font)
        fontHeight = Font.getHeight("a", font)

        cols = Math.floor(dimensions[0] / fontWidth)
        rows = Math.floor(dimensions[1] / fontHeight)

        console.log dimensions
        console.log font
        console.log fontWidth, fontHeight
        console.log cols, rows

        @terminal.resize(cols, rows)
        @process.resize(cols, rows)

    # Public: returns the parent panel {PanelView}
    getParent: ->
        return $(@parent()[0])

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
