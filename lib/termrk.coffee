

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

        @subscriptions.add atom.commands.add 'atom-workspace',
            'termrk:toggle': => @toggle()

        @panel = atom.workspace.addBottomPanel(
            item: @getActiveTerminal().getElement()
            visible: false )
        @panelView = $(atom.views.getView(@panel))

        @panelView.height '400px'
        console.log @panelView

        @$ = $
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

            dimensions = [@panelView.width(), @panelView.height()]
            font       = @activeTerminal.terminalView.css('font')
            fontWidth  = Font.getWidth("a", font)
            fontHeight = Font.getHeight("a", font)

            cols = dimensions[0] / fontWidth
            rows = dimensions[1] / fontHeight
