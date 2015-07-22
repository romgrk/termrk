
_   = require 'underscore-plus'
Q   = require 'q'
$   = require 'jquery.transit'
pty = require 'pty.js'

{Emitter}             = require 'atom'
{CompositeDisposable} = require 'atom'
{$$, View}            = require 'space-pen'
{Key, KeyKit}         = require 'keykit'
{Task} = require 'atom'

window.termjs = require 'term.js' if window.debug?

Termrk     = require './termrk'
TermrkView = require './termrk-view'
Terminal   = require './termjs-fix'

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

    process: null
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

    attachListeners: ->

    # Private: starts pty.js child process
    spawnProcess: (options={}) ->
        shell = options.shell ? Config.getDefaultShell()

        options.name = options.name ? 'xterm-256color'
        options.cwd  = options.cwd ? Config.getStartingDir()
        options.cols = 400
        options.rows = 24

        try
            @process = Task.once require.resolve('./pty-task'), shell, [], options
        catch error
            error.message += "\nshell: #{shell}"
            throw error

        @process.on 'data', (data) =>
            @emitter.emit 'data', data

        @process.on 'exit', (code, signal) =>
            delete @process
            @emitter.emit 'exit', {code, signal}
            @spawnProcess() if @restartShell

        @emitter.emit 'start', shell
        return

    ###
    Section: commands
    ###

    # Public: writes data to the process
    write: (data) ->
        # console.log JSON.stringify data
        @process.send(event: 'input', text: data)

    # Public: resize the process buffer
    resize: (cols, rows) ->
        if typeof cols is 'object'
            @process.send(event: 'resize', cols.cols, rows.rows)
        else if _.isArray(cols)
            @process.send(event: 'resize', cols[1], rows[1])
        else
            @process.send(event: 'resize', cols, rows)

    # Public: writes text from clipboard to terminal
    paste: ->
        @process.send(event: 'input', text: atom.clipboard.read())

    ###
    Section: get/set/utils
    ###

    getProcess: ->
        @process

    getPID: ->
        @process.pid

    destroy: ->
        @process.kill()

    getView: ->
        @view

    setView: (view) ->
        @view = view
