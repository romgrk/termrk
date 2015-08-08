
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
    Section: static
    ###

    @instances: new Set()

    @addInstance: (model) ->
        @instances.add(model)

    @removeInstance: (model) ->
        @instances.remove(model)

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

    pty: null
    emitter: null

    # options
    restartShell: true

    # Public: constructor
    #
    # * `options`
    #   * `.shell` - {String} shell name eg. 'bash'
    #   * `.restartShell` - {Boolean} auto-restart shell on exit
    #   * `.name` - {String} term.js: name of terminal
    #   * `.cwd` - {String} cwd of shell
    #
    constructor: (options) ->
        TermrkModel.addInstance this

        @emitter = new Emitter

        @restartShell = options.restartShell ? true

        @spawnProcess(options)

    # Private: starts pty.js child process
    spawnProcess: (options={}) ->
        shell = options.shell ? Config.getDefaultShell()

        options.name = options.name ? 'xterm-256color'
        options.cwd  = options.cwd ? Config.getStartingDir()
        options.cols = 400 # avoids init messages being cropped FIXME
        options.rows = 24

        try
            @pty = Task.once require.resolve('./pty-task'), shell, [], options
        catch error
            error.message += "\nshell: #{shell}"
            throw error

        @pty.on 'data', (data) =>
            @emitter.emit 'data', data

        @pty.on 'exit', (code, signal) =>
            delete @pty
            @emitter.emit 'exit', {code, signal}
            @spawnProcess() if @restartShell

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

    # Public: writes text from clipboard to terminal
    paste: ->
        @write(atom.clipboard.read())

    ###
    Section: get/set/utils
    ###

    getProcess: ->
        @pty

    getPID: ->
        @pty.pid

    destroy: ->
        @pty.kill?()

    getView: ->
        @view

    setView: (view) ->
        @view = view
