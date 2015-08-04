

path                  = require 'path'
interact              = require 'interact.js'
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

# TODO place this somewhere else & add more programs
programsByExtname =
    '.js':     'node'
    '.node':   'node'
    '.py':     'python'
    '.py3':    'python3'
    '.coffee': 'coffee'

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
    views:      {}
    activeView: null

    # Private: config description
    config: Config.schema

    activate: (state) ->
        @subscriptions = new CompositeDisposable()

        @setupElements()

        @registerCommands 'atom-workspace',
            'termrk:toggle':            => @toggle()
            'termrk:hide':              => @hide()
            'termrk:show':              => @show()

            'termrk:toggle-focus':      => @toggleFocus()
            'termrk:focus':             => @focus()
            'termrk:blur':              => @blur()

            'termrk:insert-selection':  @insertSelection.bind(@)
            'termrk:run-current-file':  =>
                @runCurrentFile()
                @show()

            'termrk:create-terminal':   =>
                @setActiveTerminal(@createTerminal())
                @show()
            'termrk:create-terminal-current-dir': =>
                @setActiveTerminal @createTerminal
                    cwd: Paths.current()
                @show()

        @registerCommands '.termrk',
            'termrk:trigger-keypress': =>
                @activeView.triggerKeypress()
            'termrk:insert-filename': =>
                content = atom.workspace.getActiveTextEditor().getURI()
                @activeView.write(content)
                @activeView.focus()
            'core:paste': =>
                content = atom.clipboard.read()
                @activeView.write(content)
                @activeView.focus()


        @registerCommands '.termrk',
            'termrk:close-terminal':   =>
                @removeTerminal(@getActiveTerminal())
            'termrk:activate-next-terminal':   =>
                @setActiveTerminal(@getNextTerminal())
                @show()
            'termrk:activate-previous-terminal':   =>
                @setActiveTerminal(@getPreviousTerminal())
                @show()

        # @subscriptions.add Config.observe TODO
        Config.observe
            'fontSize':   -> TermrkView.fontChanged()
            'fontFamily': -> TermrkView.fontChanged()

        @setActiveTerminal(@createTerminal())

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
        @panelView.attr('data-height', @panelHeight)
        @panelView.addClass 'termrk-panel'
        @panelView.height(0)

        @containerView = $(@panelView.find('.termrk-container'))

        @makeResizable '.termrk-panel'

    makeResizable: (element) ->
        interact(element)
        .resizable
            edges: { left: false, right: false, bottom: false, top: true }

        .on 'resizemove', (event) ->
            target = event.target
            target.style.height = event.rect.height + 'px';

        .on 'resizeend', (event) =>
            event.target.setAttribute 'data-height', event.target.style.height
            @activeView.updateTerminalSize()

    ###
    Section: elements/views creation
    ###

    createContainer: ->
        $$ ->
            @div class: 'termrk-container'

    createTerminal: (options={}) ->
        model = new TermrkModel(options)
        termrkView = new TermrkView(model)
        termrkView.height(0)

        @views[termrkView.time] = termrkView
        @containerView.append termrkView

        return termrkView

    ###
    Section: views management
    ###

    # Private: get previous terminal, sorted by creation time
    getPreviousTerminal: ->
        keys  = Object.keys(@views).sort()

        unless @activeView?
            return null if keys.length is 0
            return @views[keys[0]]

        index = keys.indexOf @activeView.time
        index = if index is 0 then (keys.length - 1) else (index - 1)
        key   = keys[index]

        return @views[key]

    # Private: get next terminal, sorted by creation time
    getNextTerminal: ->
        keys  = Object.keys(@views).sort()

        unless @activeView?
            return null if keys.length is 0
            return @views[keys[0]]

        index = keys.indexOf @activeView.time
        index = (index + 1) % keys.length
        key   = keys[index]

        return @views[key]

    getActiveTerminal: ->
        return @activeView if @activeView?
        @setActiveTerminal(@createTerminal())
        return @activeView

    setActiveTerminal: (term) ->
        return if term is @activeView

        if @panel.isVisible()
            @activeView?.animatedHide()
            @activeView?.deactivated()
            @activeView = term
            @activeView.animatedShow()
            @activeView.activated()
        else
            @activeView?.hide()
            @activeView?.height(0)
            @activeView?.deactivated()
            @activeView = term
            @activeView.show()
            @activeView.height('100%')
            @activeView.activated()

    removeTerminal: (term) ->
        return unless @views[term.time]?

        if term is @activeView
            nextTerm = @getNextTerminal()
            term.animatedHide(-> term.destroy())
            if term isnt nextTerm
                @setActiveTerminal(nextTerm)
            else
                @setActiveTerminal(@createTerminal()) # TODO optionnal?
        else
            term.destroy()

        delete @views[term.time]

    ###
    Section: commands handlers
    ###

    hide: (callback) ->
        return unless @panel.isVisible()

        @activeView?.blur()
        @restoreFocus()

        @panelView.stop()
        @panelView.transition {height: '0'}, 250, 'ease-in-out', =>
            @panel.hide()
            @activeView.deactivated()
            callback?()

    show: (callback) ->
        return if @panel.isVisible()
        @panel.show()

        @storeFocusedElement()
        @activeView?.focus()

        height = @panelView.attr('data-height') ? @panelHeight

        @panelView.stop()
        @panelView.transition {
            height: height
            }, 250, 'ease-in-out', =>
            @activeView.activated()
            callback?()

    toggle: ->
        if @panel.isVisible()
            @hide()
        else
            @show()

    insertSelection: (event) ->
        return unless @activeView?

        unless @panel.isVisible()
            @show @insertSelection.bind(@)
        else
            editor    = atom.workspace.getActiveTextEditor()
            selection = editor.getSelections()[0]

            text = selection.getText()
            text = text.replace /(\n)/g, '\\$1'

            @activeView.write text
            @activeView.focus()

    focus: () ->
        unless @panel.isVisible()
            @show => @focus()
        else
            @storeFocusedElement()
            @activeView.focus()

    blur: () ->
        @activeView.blur()
        @restoreFocus()

    toggleFocus: () ->
        return unless @activeView?
        if @activeView.hasFocus()
            @blur()
        else
            @focus()

    runCurrentFile: () ->
        file = atom.workspace.getActiveTextEditor().getURI()
        extname = path.extname file
        if (program = programsByExtname[extname])?
            @activeView.write "#{program} #{file}\n"
        # TODO search for #!

    ###
    Section: helpers
    ###

    shellEscape: (s) ->
        s.replace(/(["\n'$`\\])/g,'\\$1')

    registerCommands: (target, commands) ->
        @subscriptions.add atom.commands.add target, commands

    getPanelHeight: ->
        @panelHeight

    storeFocusedElement: ->
        @focusedElement = $(document.activeElement)

    restoreFocus: ->
        @focusedElement?.focus()
        @focusedElement = null

    deactivate: ->
        for time, term of @views
            term.destroy()
        @panel.destroy()
        @subscriptions.dispose()

    serialize: ->
        # termrkViewState: @termrkView.serialize()
