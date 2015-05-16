

{CompositeDisposable} = require 'atom'
{$, $$, View}         = require 'space-pen'

pty        = require('pty.js')
{Terminal} = require('term.js')

module.exports =
class TermrkView extends View

    # Public: {Child_process} process of the running shell
    process: null

    @content: ->
        @div class: 'termrk'

    initialize: (serializedState) ->
        @spawnProcess()
        unless @process?
            console.error "Termrk: aborting initialization"
            return

    spawnProcess: ->
        shell = process.env.SHELL || process.env.TERM || 'sh'
        options =
                name: 'xterm-color'
                cols: 80
                rows: 24
                cwd: process.cwd()

        try
            @process = pty.fork(shell, [], options)
            console.log(
                "Termrk: started process #{shell} with pid:#{@process.pid}"
                + "and fd:#{@process.fd}");
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

    setupTerminalElement: ->
        @terminal = new Terminal
            cols: 80
            rows: 24
            useStyle: true
            screenKeys: true

        @terminal.open(@element);

    # Returns an object that can be retrieved when package is activated
    serialize: ->

    # Tear down any state and detach
    destroy: ->
        @process.kill()
        @element.remove()

    getProcess: ->
        @process

    getElement: ->
        @element
