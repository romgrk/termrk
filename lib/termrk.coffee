

Path                  = require 'path'
fs                    = require 'fs-plus'
interact              = require 'interact.js'
CSON                  = require 'season'
{CompositeDisposable} = require 'atom'
{$$, View}            = require 'space-pen'
$                     = require 'jquery.transit'

TermrkView  = require './termrk-view'
TermrkModel = require './termrk-model'
Config      = require './config'
Utils       = require './utils'

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

    # Public: panel model, jQ wrapper
    panel:       null
    panelView:   null

    # Public: {CompositeDisposable}
    subscriptions: null

    # Public: {TerminalView} list and active view
    views:      {}
    activeView: null

    # Private: config description
    config: Config.schema

    # Private: user commands
    userCommands: null

    activate: (state) ->
        @$ = $
        @config = Config

        @subscriptions = new CompositeDisposable()

        @registerCommands 'atom-workspace',
            'termrk:toggle':            => @toggle()
            'termrk:hide':              => @hide()
            'termrk:show':              => @show()

            'termrk:toggle-focus':      => @toggleFocus()
            'termrk:focus':             => @focus()
            'termrk:blur':              => @blur()

            'termrk:insert-selection':  =>
                @insertSelection()
                @show()
            'termrk:run-current-file':  =>
                @runCurrentFile()
                @show()

            'termrk:create-terminal':   =>
                @setActiveTerminal @createTerminal()
                @show()
            'termrk:create-terminal-current-dir': =>
                return unless (currentDir = Utils.getCurrentDir())?
                @setActiveTerminal @createTerminal(cwd: currentDir)
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
            'termrk:close-terminal':   =>
                @removeTerminal(@getActiveTerminal())
            'termrk:activate-next-terminal':   =>
                @setActiveTerminal(@getNextTerminal())
                @show()
            'termrk:activate-previous-terminal':   =>
                @setActiveTerminal(@getPreviousTerminal())
                @show()

        @loadUserCommands()

        @loadKeymap()

        @subscriptions.add Config.observe
            'fontSize':   -> TermrkView.fontChanged()
            'fontFamily': -> TermrkView.fontChanged()
            'useDefaultKeymap': @loadKeymap.bind(@)

        # Create elements and activate
        @setupElements()

        @setActiveTerminal(@createTerminal())

        window.termrk = @ if window.debug == true

    setupElements: ->
        @containerView = @createContainer()

        @panel = atom.workspace.addBottomPanel(
            item: @containerView
            visible: false )

        @panelView = $(atom.views.getView(@panel))
        @panelView.addClass 'termrk-panel'
        @panelView.attr('data-height', Config.defaultHeight)
        @panelView.height(0)

        @makeResizable '.termrk-panel'

    makeResizable: (element) ->
        interact(element)
        .resizable
            edges: { left: false, right: false, bottom: false, top: true }

        .on 'resizemove', (event) ->
            target = event.target
            target.style.height = event.rect.height + 'px';

        .on 'resizeend', (event) =>
            Config.defaultHeight = parseInt event.target.style.height
            @panelView.attr 'data-height', Config.defaultHeight
            @activeView.updateTerminalSize()

    ###
    Section: elements/views creation
    ###

    createContainer: ->
        $$ ->
            @div class: 'termrk-container'

    createTerminal: (options={}) ->
        termrkView = new TermrkView
        @containerView.append termrkView
        @views[termrkView.time] = termrkView # TODO manage by css selector

        [cols, rows] = termrkView.calculateTerminalDimensions(
            termrkView.find('.terminal').width(), Config.defaultHeight)
        cols = 80 if cols < 80 # FIXME

        options.cols ?= cols
        options.rows ?= rows

        termrkView.start(options)

        termrkView.height(0)
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

        window.term = @activeView if window.debug == true
        window.termjs = @activeView.termjs if window.debug == true

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

        @panelView.stop()
        @panelView.transition {
            height: "#{Config.defaultHeight-2}px"
            }, 250, 'ease-in-out', =>
            @activeView?.activated()
            callback?()

    toggle: ->
        if @panel.isVisible()
            @hide()
        else
            @show()

    # Private: insert selected text in active terminal
    insertSelection: (event) ->
        return unless @activeView?
        editor = atom.workspace.getActiveTextEditor()
        @activeView.write sel.getText()  for sel in editor.getSelections()
        @activeView.focus()

    # Public: focus active terminal and show panel if it isnt visisble
    focus: () ->
        unless @panel.isVisible()
            @show => @focus()
        else
            @storeFocusedElement() unless @focusedElement?
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
        extname = Path.extname file

        firstLine = atom.workspace.getActiveTextEditor().lineTextForBufferRow(0)
        if (shebang = firstLine.match /#!(.+)$/)
            program = shebang[1]
        else if programsByExtname[extname]?
            program = programsByExtname[extname]
        else
            console.log "Termrk: couldnt run file #{file}"
            return

        @activeView.write "#{program} #{file}\n"
        @focus()

    runUserCommand: (commandName, event) ->
        command = @userCommands[commandName].command

        command = command.replace /\$FILE/g, Utils.getCurrentFile()
        command = command.replace /\$DIR/g, Utils.getCurrentDir()
        command = command.replace /\$PROJECT/g, Utils.getProjectDir()

        unless command[-1..] is '\n'
            command += '\n'

        @activeView.write(command)
        @focus()

    ###
    Section: helpers
    ###

    # createEditorFile: ->
    #     editorFile = Utils.resolve Utils.getTmpDir(), 'editor'
    #     content = atom.workspace.getActiveTextEditor().getText()
    #     fs.writeFileSync editorFile, content

    loadUserCommands: ->
        userCommandsFile = Utils.resolve(
            atom.getConfigDirPath(), Config.userCommandsFile)
        try
            @userCommands = CSON.readFileSync userCommandsFile
        catch error
            console.log "Termrk: couldn't load commands in #{userCommandsFile}"
            console.error error if window.debug
            @userCommands = {}
            return

        for commandName, description of @userCommands
            scope = description.scope ? 'atom-workspace'
            @registerCommands scope, "termrk:command-#{commandName}",
                @runUserCommand.bind(@, commandName)

    registerCommands: (args...) ->
        @subscriptions.add atom.commands.add args...

    # Private: updates package keymap
    loadKeymap: ->
        keymapPath = Path.resolve __dirname, '../res/termrk.cson'
        if Config.useDefaultKeymap
            atom.keymaps.loadKeymap(keymapPath)
            console.log 'loaded ', keymapPath
        else
            atom.keymaps.removeBindingsFromSource keymapPath
            console.log 'removed ', keymapPath


    shellEscape: (s) ->
        s.replace(/(["\n'$`\\])/g,'\\$1')

    getPanelHeight: ->
        Config.defaultHeight

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
