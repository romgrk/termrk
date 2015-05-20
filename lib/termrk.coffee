

{CompositeDisposable} = require 'atom'
{$$, View}            = require 'space-pen'
$                     = require 'jquery.transit'

TermrkView = require './termrk-view'
{Font, Config} = require './utils'


module.exports = Termrk =

    # Public: panel's children and jQuery wrapper
    container:     null
    containerView: null

    # Public: panel model, jQ wrapper and default height
    panel:       null
    panelView:   null
    panelHeight: null

    # Public: {CompositeDisposable}
    subscriptions: null

    # Public: {TerminalView} list and active view
    terminals:      {}
    activeTerminal: null

    # Private: config description
    config:
        'defaultHeight':
            description: 'Default height of the terminal-panel (in px)'
            type:        'integer'
            default:     300
        'shellCommand':
            description: 'Command to call to start the shell. (auto-detect by default)'
            type:        'string'
            default:     'auto'
        'unfocusKeystroke':
            description: 'KeyStroke that hides the terminal when it is focused. (atom keymap format)'
            type:        'string'
            default:     'escape'

    activate: (state) ->
        @subscriptions = new CompositeDisposable

        @container = @createContainer()

        @panel = atom.workspace.addBottomPanel(
            item: @container
            visible: false )

        @panelHeight = Config.get('defaultHeight')
        if not @panelHeight? or typeof @panelHeight isnt "number"
            @panelHeight = 300

        @panelView = $(atom.views.getView(@panel))
        @panelView.height(@panelHeight + 'px')
        @panelView.addClass 'termrk-panel'
        @panelView.on 'resize', ->
            console.log 'panel resize'

        @containerView = $(@panelView.find('.termrk-container'))
        @containerView.on 'resize', ->
            console.log 'container resize'

        @workspaceCommands =
            'termrk:toggle':            => @toggle()
            'termrk:hide':              => @hide()
            'termrk:show':              => @show()
            'termrk:create-terminal':   => @setActiveTerminal(@createTerminal())
            'termrk:activate-next-terminal':   => @setActiveTerminal(@getNextTerminal())
            'termrk:activate-previous-terminal':   => @setActiveTerminal(@getPreviousTerminal())

        @subscriptions.add atom.commands.add 'atom-workspace', @workspaceCommands

        @setActiveTerminal(@createTerminal())

        @activeTerminal.updateTerminalSize()

        @$ = $
        window.termrk = @

    ###
    Section: elements/views creation
    ###

    createContainer: ->
        container = document.createElement('div')
        container.classList.add 'termrk-container'
        return container

    createTerminal: () ->
        termrkView = new TermrkView()

        @terminals[termrkView.time] = termrkView

        @containerView.append termrkView

        return termrkView

    ###
    Section: terminals management
    ###

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

    ###
    Section: commands handlers
    ###

    hide: ->
        return unless @panel.isVisible()
        @panelHeight = @panelView.height()
        @panelView.transition {height: '0'}, 250, 'ease-in-out', =>
            @panel.hide()
            @activeTerminal.deactivated()
            @restoreFocus()

    show: ->
        return if @panel.isVisible()
        @storeFocusedElement()
        @panel.show()
        @panelView.transition {height: @panelHeight}, 250, 'ease-in-out', =>
            @activeTerminal.activated()

    toggle: ->
        if @panel.isVisible()
            @hide()
        else
            @show()

    ###
    Section: helpers
    ###

    getPanelHeight: ->
        @panelHeight

    storeFocusedElement: ->
        @focusedElement = document.activeElement

    restoreFocus: ->
        @focusedElement?.focus()

    deactivate: ->
        for time, term of @terminals
            term.destroy()
        @panel.destroy()
        @subscriptions.dispose()

    serialize: ->
        termrkViewState: @termrkView.serialize()
