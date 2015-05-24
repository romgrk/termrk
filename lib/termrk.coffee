

{CompositeDisposable} = require 'atom'
{$$, View}            = require 'space-pen'
$                     = require 'jquery.transit'

TermrkView  = require './termrk-view'
TermrkModel = require './termrk-model'
Config      = require './config'
Utils       = require './utils'
Font        = Utils.Font
Keymap      = Utils.Keymap
Paths       = Utils.Paths


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
    config: Config.schema

    activate: (state) ->
        @subscriptions = new CompositeDisposable

        @setupElements()

        @registerCommands 'atom-workspace',
            'termrk:toggle':            => @toggle()
            'termrk:hide':              => @hide()
            'termrk:show':              => @show()
            'termrk:create-terminal':   =>
                @setActiveTerminal(@createTerminal())
            'termrk:create-terminal-current-dir': =>
                @setActiveTerminal @createTerminal
                    cwd: Paths.current()

        @registerCommands '.termrk',
            'termrk:close-terminal':   =>
                @removeTerminal(@getActiveTerminal())
            'termrk:activate-next-terminal':   =>
                @setActiveTerminal(@getNextTerminal())
            'termrk:activate-previous-terminal':   =>
                @setActiveTerminal(@getPreviousTerminal())

        @subscriptions.add Config.observe
            'fontSize':   -> TermrkView.fontChanged()
            'fontFamily': -> TermrkView.fontChanged()

        @setActiveTerminal(@createTerminal())
        @activeTerminal.updateTerminalSize()

        @$ = $
        window.termrk = @

    setupElements: ->
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

    ###
    Section: elements/views creation
    ###

    # createContainer: ->
    #     container = document.createElement('div')
    #     container.classList.add 'termrk-container'
    #
    #     resizeHandle = document.createElement('div')
    #     resizeHandle.classList.add 'resize-handle'
    #
    #     container.appendChild resizeHandle
    #
    #     return container

    createContainer: ->
        $$ ->
            @div class: 'resize-container', =>
                @div class: 'resize-handle'
                @div class: 'termrk-container'

    createTerminal: (options={}) ->
        model = new TermrkModel(options)
        termrkView = new TermrkView(model)
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
                @setActiveTerminal(nextTerm)
            else
                @setActiveTerminal(@createTerminal())
        else
            term.destroy()

        delete @terminals[term.time]

    ###
    Section: commands handlers
    ###

    hide: ->
        return unless @panel.isVisible()

        @panelView.stop()
        @panelView.transition {height: '0'}, 250, 'ease-in-out', =>
            @panel.hide()
            @activeTerminal.deactivated()
            @restoreFocus()

    show: ->
        return if @panel.isVisible()
        @storeFocusedElement()
        @panel.show()
        @panelView.stop()
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

    registerCommands: (target, commands) ->
        @subscriptions.add atom.commands.add target, commands

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
