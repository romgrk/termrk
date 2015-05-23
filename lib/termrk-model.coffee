
Q   = require 'q'
$   = require 'jquery.transit'
pty = require 'pty.js'

{CompositeDisposable} = require 'atom'
{$$, View}            = require 'space-pen'
{Key, KeyKit}         = require 'keykit'

window.termjs = require 'term.js' if window.debug?

Termrk     = require './termrk'
TermrkView = require './termrk-view'
Terminal   = require './termjs-fix'

Utils  = require './utils'
Config = new Utils.Config('termrk')
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
    Section: instance
    ###

    constructor: (options) ->
        TermrkModel.addInstance this
