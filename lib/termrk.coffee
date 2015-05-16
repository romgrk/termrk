

{CompositeDisposable} = require 'atom'
{$$, View}            = require 'space-pen'
$                     = require 'jquery.transit'

TermrkView = require './termrk-view'
{Font, Config} = require './utils'


module.exports = Termrk =

    container: null

    panel:       null
    panelView:   null
    panelHeight: null

    subscriptions: null

    activeTerminal: null
    terminals:      {}

    config:
        'defaultHeight':
            description: 'Default height of the terminal-panel'
            type: 'integer'
            default: 300
        'shellCommand':
            description: 'Command to call to start the shell. (auto-detect by default)'
            type: 'string'
            default: 'auto'

    activate: (state) ->
        @subscriptions = new CompositeDisposable

        @container = @createContainer()

        @panel = atom.workspace.addBottomPanel(
            item: @container
            visible: false )

        @panelHeight = Config.get('defaultHeight')
        
        @panelView   = $(atom.views.getView(@panel))
        @panelView.height(@panelHeight)

        @containerView = $(@panelView.find('.termrk-container'))

        @subscriptions.add atom.commands.add 'atom-workspace',
            'termrk:toggle':            => @toggle()
            'termrk:create-terminal':   => @setActiveTerminal(@createTerminal())
            'termrk:activate-next-terminal':   =>
                @setActiveTerminal(@getNextTerminal())
            'termrk:activate-previous-terminal':   =>
                @setActiveTerminal(@getPreviousTerminal())

        @setActiveTerminal(@createTerminal())

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

        return termrkView

    getPreviousTerminal: ->
        keys  = Object.keys(@terminals).sort()

        unless @activeTerminal?
            return null if keys.length is 0
            return @terminals[keys[0]]

        index = keys.indexOf @activeTerminal.time
        index = if index is 0 then (keys.length - 1) else (index - 1)
        key   = keys[index]

        console.log 'keys', keys
        console.log 'active', @activeTerminal.time
        console.log 'index %i', index

        return @terminals[key]

    getNextTerminal: ->
        keys  = Object.keys(@terminals).sort()

        unless @activeTerminal?
            return null if keys.length is 0
            return @terminals[keys[0]]

        index = keys.indexOf @activeTerminal.time
        index = (index + 1) % keys.length
        key   = keys[index]

        console.log 'keys', keys
        console.log 'active', @activeTerminal.time
        console.log 'index %i', index

        return @terminals[key]

    getActiveTerminal: ->
        return @activeTerminal if @activeTerminal?
        @setActiveTerminal(@createTerminal())
        return @activeTerminal

    setActiveTerminal: (term) ->
        console.log 'set active:', term
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

    getPanelHeight: ->
        @panelHeight

    deactivate: ->
        for time, term of @terminals
            term.destroy()
        @panel.destroy()
        @subscriptions.dispose()

    serialize: ->
        termrkViewState: @termrkView.serialize()

    toggle: ->
        if @panel.isVisible()
            @panelHeight = @panelView.height()
            @panelView.transition {height: '0'}, 250, 'ease-in-out', =>
                @panel.hide()
                @activeTerminal.deactivated()
                @restoreFocus()
        else
            @storeFocusedElement()
            @panel.show()
            @panelView.transition {height: @panelHeight}, 250, 'ease-in-out', =>
                @activeTerminal.activated()

    storeFocusedElement: ->
        @focusedElement = document.activeElement

    restoreFocus: ->
        @focusedElement?.focus()
