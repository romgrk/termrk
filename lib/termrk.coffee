

{CompositeDisposable} = require 'atom'
{$, $$, View}         = require 'space-pen'

TermrkView = require './termrk-view'
{Font} = require './utils'


module.exports = Termrk =

    container: null

    panel:     null
    panelView: null

    subscriptions: null

    activeTerminal: null
    terminals:      {}

    config:
        'defaultHeight':
            description: 'Default height of the terminal-panel'
            type: 'integer'
            default: 400

    activate: (state) ->
        @subscriptions = new CompositeDisposable

        @container = @createContainer()

        @panel = atom.workspace.addBottomPanel(
            item: @container
            visible: false )

        @panelView = $(atom.views.getView(@panel))
        @panelView.height '400px'

        console.log atom.config.get('termrk.defaultHeight')

        @containerView = $(@panelView.find('.termrk-container'))

        @subscriptions.add atom.commands.add 'atom-workspace',
            'termrk:toggle':            => @toggle()
            'termrk:create-terminal':   => @createTerminal()
            'termrk:activate-next-terminal':   =>
                @setActiveTerminal(@getNextTerminal())
            'termrk:activate-previous-terminal':   =>
                @setActiveTerminal(@getPreviousTerminal())

        @createTerminal()
        @activeTerminal.updateTerminalSize()

        @$ = $
        window.termrk = @

    createContainer: ->
        container = document.createElement('div')
        container.classList.add 'termrk-container'
        return container

    createTerminal: () ->
        termrkView = new TermrkView()

        @terminals[termrkView.time] = termrkView

        @containerView.append termrkView

        @setActiveTerminal(termrkView)
        return termrkView

    getPreviousTerminal: ->
        return unless @activeTerminal?

        keys  = Object.keys(@terminals).sort()
        index = keys.indexOf @activeTerminal.time
        return null if index == -1

        index = if index is 0 then (keys.length - 1) else (index - 1)
        key   = keys[index]
        return @terminals[key]

    getNextTerminal: ->
        return unless @activeTerminal?

        keys  = Object.keys(@terminals).sort()
        index = keys.indexOf @activeTerminal.time
        return null if index == -1

        index = (index + 1) % keys.length
        key   = keys[index]
        return @terminals[key]

    getActiveTerminal: ->
        @activeTerminal ?= @createTerminal()

    setActiveTerminal: (term) ->
        return if term is @activeTerminal
        @activeTerminal?.animatedHide()
        @activeTerminal?.deactivated()
        @activeTerminal = term
        @activeTerminal.animatedShow()
        @activeTerminal.activated()

    removeTerminal: (term) ->
        return unless @terminals[term.time]?

        if term is @activeTerminal
            nextTerm = @getNextTerminal()
            term.animatedHide(-> term.destroy())
            if term isnt nextTerm
                nextTerm.animatedShow()
        else
            term.destroy()

        delete @terminals[term.time]

    deactivate: ->
        for time, term of @terminals
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
            @activeTerminal.activated()
