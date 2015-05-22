

{CompositeDisposable} = require 'atom'
{$$, View}            = require 'space-pen'
$                     = require 'jquery.transit'

TermrkView = require './termrk-view'
Utils      = require './utils'
Config     = new Utils.Config('termrk')
Font       = Utils.Font


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
        # Shell options
        'shellCommand':
            title:       'Command'
            description: 'Command to call to start the shell. (auto-detect or executable file)'
            type:        'string'
            default:     'auto-detect'
        'startingDir':
            title:       'Start dir'
            description: 'Dir where the shell should be started'
            type:        'string'
            default:     'project'
            enum:        ['home', 'project', 'cwd']

        # Rendering options
        'defaultHeight':
            title:       'Panel height'
            description: 'Default height of the terminal-panel (in px)'
            type:        'integer'
            default:     300
        'fontSize':
            title:       'Font size'
            description: 'CSS style, defaults to px if no unit is specified'
            type:        'string'
            default:     '14px'
        'fontFamily':
            title:       'Font family'
            type:        'string'
            default:     'Monospace'


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
            console.log 'panel resize' if window.debug?

        @containerView = $(@panelView.find('.termrk-container'))
        @containerView.on 'resize', ->
            console.log 'container resize' if window.debug?

        @workspaceCommands =
            'termrk:toggle':            => @toggle()
            'termrk:hide':              => @hide()
            'termrk:show':              => @show()
            'termrk:create-terminal':   => @setActiveTerminal(@createTerminal())
            'termrk:activate-next-terminal':   => @setActiveTerminal(@getNextTerminal())
            'termrk:activate-previous-terminal':   => @setActiveTerminal(@getPreviousTerminal())

        @configKeys =
            'fontSize':   -> TermrkView.fontChanged()
            'fontFamily': -> TermrkView.fontChanged()

        @subscriptions.add atom.commands.add 'atom-workspace', @workspaceCommands
        @subscriptions.add Config.observe @configKeys

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
        termrkView.height(0)

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

        return @terminals[key]

    getNextTerminal: ->
        keys  = Object.keys(@terminals).sort()

        unless @activeTerminal?
            return null if keys.length is 0
            return @terminals[keys[0]]

        index = keys.indexOf @activeTerminal.time
        index = (index + 1) % keys.length
        key   = keys[index]

        return @terminals[key]

    getActiveTerminal: ->
        return @activeTerminal if @activeTerminal?
        @setActiveTerminal(@createTerminal())
        return @activeTerminal

    setActiveTerminal: (term) ->
        console.log 'set active:', term if window.debug?
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
        # termrkViewState: @termrkView.serialize()
