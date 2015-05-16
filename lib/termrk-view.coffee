

{CompositeDisposable} = require 'atom'
{$, $$, View}         = require 'space-pen'

pty        = require('pty.js')
{Terminal} = require('term.js')

module.exports =
class TermrkView extends View

    process: null

    @content: ->
        @div class: 'termrk'


    initialize: (serializedState) ->
        console.log 'TermrkView initialize'

        @terminal = new Terminal
        @process = pty.fork(
            process.env.SHELL || process.env.TERM || 'sh', [], {
                name: 'xterm-color'
                cols: 80
                rows: 24
                cwd: process.cwd() }
            )

        console.log(''
            + 'Created shell with pty master/slave'
            + ' pair (master: %d, pid: %d)',
            @process.fd, @process.pid);

        @terminal = new Terminal
            cols: 80
            rows: 24
            useStyle: true
            screenKeys: true

        @terminal.open(@element);

        @process.on 'data', (data) =>
            @terminal.write data

        @process.on 'exit', (code, signal) ->
            console.log "Process: exit(%s) and signal %s",
                code, signal

        @terminal.on 'data', (data) =>
            @process.write(data)

        # @terminal.write('\x1b[31mWelcome to term.js!\x1b[m\r\n');
        # @process.write('ls\r');

    # Returns an object that can be retrieved when package is activated
    serialize: ->

    # Tear down any state and detach
    destroy: ->
        @process.kill()
        @element.remove()

    getTerminalElement: ->
        @find('.terminal')[0]

    getElement: ->
        @element
