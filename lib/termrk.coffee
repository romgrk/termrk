

{CompositeDisposable} = require 'atom'

TermrkView = require './termrk-view'


module.exports = Termrk =

    termrkView: null
    panel: null
    subscriptions: null

    activeTerminal: null
    terminals: []

    activate: (state) ->
        @subscriptions = new CompositeDisposable

        @subscriptions.add atom.commands.add 'atom-workspace',
            'termrk:toggle': => @toggle()

        @panel = atom.workspace.addBottomPanel(
            item: @getActiveTerminal().getElement()
            visible: false )
        @panelView = atom.views.getView(@panel)

        window.termrk = @

    createTerminal: () ->
        termrkView = new TermrkView()
        @terminals.push termrkView
        return termrkView

    getActiveTerminal: ->
        @activeTerminal ?= @createTerminal()

    setActiveTerminal: (term) ->
        @activeTerminal = term

    deactivate: ->
        @panel.destroy()
        @subscriptions.dispose()
        @termrkView.destroy()

    serialize: ->
        termrkViewState: @termrkView.serialize()

    toggle: ->
        console.log 'Termrk was toggled!'

        if @panel.isVisible()
            @panel.hide()
        else
            @panel.show()
            @panelView.height @getActiveTerminal.getTerminalElement().height()
