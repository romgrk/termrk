###
    Atom-terminal-panel
    Copyright by isis97
    MIT licensed

    The panel, which manages all the terminal instances.
###

_                 = require 'underscore-plus'
domify            = require 'domify'

{View}            = require 'atom-space-pen-views'

core              = require './cli-core'
CommandOutputView = require './command-output-view'
{System}          = require './system'

module.exports =
class CliStatusView extends View

    @createSpecsCommandView = () ->
        termStatus = domify '<span class="cli-status icon icon-terminal"></span>'
        commandOutputView = new CommandOutputView
        commandOutputView.statusIcon = termStatus
        commandOutputView.statusView = this
        commandOutputView.init()
        return commandOutputView

    @content: ->
        @div class: 'cli-status inline-block', =>
            @span outlet: 'statusIconsContainer', =>
                @span click: 'eventCreateNew', class: "cli-status icon icon-plus"

    # Public: {Array} of open terminals {CommandOutputView}
    commandViews: []

    # Public: active view {CommandOutputView}
    activeView: null

    initialize: (serializeState) ->
        atom.commands.add 'atom-workspace',
            'atom-terminal-panel:new': => @eventCreateNew()
            'atom-terminal-panel:toggle': => @toggle()
            'atom-terminal-panel:next': => @activateNextCommandView()
            'atom-terminal-panel:prev': => @activatePreviousCommandView()
            'atom-terminal-panel:destroy': => @destroyActiveView()
            'atom-terminal-panel:compile': => @getForcedActivateCommandView().compile()

        @attach()

    addIcon: (icon) ->
        @statusIconsContainer.append(icon)

    createCommandView: ->
        commandOutputView = new CommandOutputView(this)

        @statusIconsContainer.append    commandOutputView.statusIcon
        @commandViews.push              commandOutputView
        @setActiveCommandView           commandOutputView

        return commandOutputView

    activateNextCommandView: ->
        index = @commandViews.indexOf(@getActiveCommandView())
        index = (index + 1) % @commandViews.length

        @setActiveCommandView @commandViews[index]

    activatePreviousCommandView: ->
        index = @commandViews.indexOf(@getActiveCommandView()) - 1
        index = @commandViews.length - 1 if index < 0

        @setActiveCommandView @commandViews[index]

    getForcedActivateCommandView: () ->
        if @getActiveCommandView() != null && @getActiveCommandView() != undefined
            return @getActiveCommandView()
        ret = @activateCommandView(0)
        @toggle()
        return ret

    setActiveCommandView: (view) ->
        unless view? and (view isnt @activeView)
            return
        # TODO optional?
        @activeView?.close()
        @activeView = view
        @activeView.open()

    getActiveCommandView: ->
        @activeView ?= @createCommandView()

    removeCommandView: (view) ->
        @commandViews = _.without @commandViews, view
        view.destroy()

    eventCreateNew: ->
        @createCommandView().toggle()

    destroyActiveView: ->
        @removeCommandView(
            @getActiveCommandView())

    attach: ->
        document.querySelector("status-bar").addLeftTile(item: this, priority: 100)

    destroy: ->
        for view in @commandViews
            view.destroy()
        @commandViews = null
        @detach()

    toggle: ->
        console.debug 'toggle', @
        @getActiveCommandView().toggle()
