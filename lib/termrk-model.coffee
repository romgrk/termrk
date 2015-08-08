
_   = require 'underscore-plus'
pty = require 'pty.js'

{Task, Emitter} = require 'atom'

Termrk     = require './termrk'
TermrkView = require './termrk-view'

Config = require './config'
Utils  = require './utils'
Font   = Utils.Font
Keymap = Utils.Keymap
Paths  = Utils.Paths

module.exports =
class TermrkModel

    ###
    Section: Events
    ###

    onDidExitProcess: (callback) ->
        @emitter.on 'exit', callback

    onDidStartProcess: (callback) ->
        @emitter.on 'start', callback

    onDidReceiveData: (callback) ->
        @emitter.on 'data', callback

    ###
    Section: instance
    ###

    pty:     null
    emitter: null

    options: null

    # Public: constructor
    #
    # * `options`
    #   * `.shell` - {String} shell name eg. 'bash'
    #   * `.restartShell` - {Boolean} auto-restart shell on exit
    #   * `.name` - {String} term.js: name of terminal
    #   * `.cwd` - {String} cwd of shell
    #   * `.cols` - {Int} terminal columns
    #   * `.rows` - {Int} terminal rows
    #
    constructor: (@options={}) ->
        @emitter = new Emitter
        @spawnProcess()

    # Public: starts pty.js child process
    spawnProcess: (shell, options) ->
        return if @pty?
        @options       ?= {}
        @options.shell = shell if shell?
        _.extend @options, options

        @options.name  ?= 'xterm-256color'
        @options.shell ?= Config.getDefaultShell()
        @options.cwd   ?= Config.getStartingDir()
        @options.cols  ?= 200 # avoids init messages being cropped FIXME
        @options.rows  ?= 24

        try
            @pty = Task.once require.resolve('./pty-task'),
                @options.shell, [], @options
        catch error
            error.message += "\n#{JSON.stringify @options}"
            throw error

        @pty.on 'data', (data) =>
            @emitter.emit 'data', data

        @pty.on 'exit', (code, signal) =>
            delete @pty
            @emitter.emit 'exit', {code, signal}
            @spawnProcess() if @options.restartShell

        @emitter.emit 'start', shell

    ###
    Section: commands
    ###

    # Public: writes data to the process
    write: (data) ->
        # console.log JSON.stringify data
        @pty.send(event: 'input', text: data)

    # Public: resize the process buffer
    resize: (cols, rows) ->
        @pty.send(event: 'resize', cols: cols, rows: rows)

    ###
    Section: get/set/utils
    ###

    getProcess: ->
        @pty

    getPID: ->
        @pty.pid

    kill: ->
        @pty?.kill()

    destroy: ->
        @pty?.destroy()

    getView: ->
        @view

    setView: (view) ->
        @view = view
