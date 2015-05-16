

{CompositeDisposable} = require 'atom'
{$, $$, View}         = require 'space-pen'

TermrkView = require './termrk-view'
{Font} = require './utils'


module.exports = Termrk =

    termrkView: null
    panel: null
    subscriptions: null

    activeTerminal: null
    terminals: []

    activate: (state) ->
        @subscriptions = new CompositeDisposable

        @panel = atom.workspace.addBottomPanel(
            item: @getActiveTerminal().getElement()
            visible: false )

        @panelView = $(atom.views.getView(@panel))
        @panelView.height '400px'

        @subscriptions.add atom.commands.add 'atom-workspace',
            'termrk:toggle': => @toggle()
            'termrk:create-terminal': => @createTerminal()

        @$ = $
        window.termrk = @

    createTerminal: () ->
        if @activeTerminal?
            @activeTerminal.animatedHide()

        termrkView = new TermrkView()
        termrkView.height('0')
        @terminals.push termrkView
        @setActiveTerminal(termrkView)
        return termrkView

    getActiveTerminal: ->
        @activeTerminal ?= @createTerminal()

    setActiveTerminal: (term) ->
        return if term is @activeTerminal
        @activeTerminal.animatedHide()
        @activeTerminal = term
        @activeTerminal.animatedShow()

    deactivate: ->
        for term in @terminals
            term.destroy()
        @panel.destroy()
        @subscriptions.dispose()

    serialize: ->
        termrkViewState: @termrkView.serialize()

    toggle: ->
        if @panel.isVisible()
            @panel.hide()
        else
            @panel.show()
            @activeTerminal.updateTerminalSize()
