
Path                  = require 'path'
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
    '.pl':     'swipl'

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
    views:      []
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
            'termrk:close-terminal': =>
                @removeCurrentView()
            'termrk:activate-next-terminal':   =>
                @setActiveTerminal(@getNextTerminal())
                @show()
            'termrk:activate-previous-terminal':   =>
                @setActiveTerminal(@getPreviousTerminal())
                @show()

        @loadUserCommands()

        @subscriptions.add Config.observe
            'fontSize':   -> TermrkView.fontChanged()
            'fontFamily': -> TermrkView.fontChanged()
            'terminalColors': (values) -> TermrkView.colorsChanged(values)

        # Create elements and activate
        @setupElements()

        view = @createTerminal()
        @setActiveTerminal(view)

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
        @views.push termrkView

        [cols, rows] = termrkView.calculateTerminalDimensions(
            @panelView.width(), Config.defaultHeight)
        cols = 80 if cols < 80 # FIXME

        options.cols ?= cols
        options.rows ?= rows

        termrkView.start(options)

        termrkView.height(0) # FIXME
        return termrkView

    ###
    Section: views management
    ###

    # Private: get previous terminal, sorted by creation time
    getPreviousTerminal: ->
        unless @activeView?
            return null if @views.length is 0
            return @views[0]

        index = @views.indexOf @activeView
        index = if index is 0 then (@views.length - 1) else (index - 1)

        return @views[index]

    # Private: get next terminal, sorted by creation time
    getNextTerminal: ->
        unless @activeView?
            return null if @views.length is 0
            return @views[0]

        index = if index is 0 then (@views.length - 1) else (index - 1)

        index = @views.indexOf @activeView
        index = (index + 1) % @views.length

        return @views[index]

    getActiveView: ->
        if @activeView?
            return @activeView
        return null

    setActiveTerminal: (term) ->
        return unless term?
        return if term is @activeView

        # if not @panel.isVisible()
            # @show()

        @activeView?.animatedHide()
        #@activeView.deactivated()

        @activeView = term
        @activeView.animatedShow()
        #@activeView.activated()

        window.term = @activeView if window.debug == true
        #window.termjs = @activeView.termjs if window.debug == true

    # @deprecated
    removeTerminal: ->
        @removeCurrentView()

    removeCurrentView: ->
        return if @views.length == 0 or not @activeView?
        view = @activeView
        index = @views.indexOf @activeView

        if @views.length == 1
            nextTerm = @createTerminal()
        else
            nextTerm = @getNextTerminal()

        @views.splice(index, 1)
        @activeView = nextTerm

        view.animatedHide(() ->
            view?.destroy())
        nextTerm.animatedShow()
        nextTerm.activated()

    ###
    Section: commands handlers
    ###

    hide: (callback) ->
        return unless @panel.isVisible()

        @activeView?.blur()
        @restoreFocus()

        @panelView.stop()
        @panelView.transition {
            height: '0'
            duration: Config.transitionDuration
            easing:   Config.transitionEasing }, =>
            @panel.hide()
            # @activeView.deactivated()
            callback?()

    show: (callback) ->
        return if @panel.isVisible()
        @panel.show()

        @storeFocusedElement()
        @activeView?.focus()

        @panelView.stop()
        @panelView.transition {
            height: "#{Config.defaultHeight-2}px"
            duration: Config.transitionDuration
            easing:   Config.transitionEasing }, =>
            @activeView?.updateTerminalSize()
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

    # Private: load the userCommands file or fail silently
    loadUserCommands: ->
        userCommandsFile = Utils.resolve(
            atom.getConfigDirPath(), Config.userCommandsFile)
        try
            @userCommands = CSON.readFileSync userCommandsFile
        catch error
            console.log "Termrk: couldn't load commands in #{userCommandsFile}"
            if error.code != "ENOENT"
              console.error error if window.debug == true
            @userCommands = {}
            return

        for commandName, description of @userCommands
            scope = description.scope ? 'atom-workspace'
            @registerCommands scope, "termrk:command-#{commandName}",
                @runUserCommand.bind(@, commandName)

    registerCommands: (args...) ->
        @subscriptions.add atom.commands.add args...

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
        for view in @views
            view?.destroy()
        @panel.destroy()
        @subscriptions.dispose()

    # Public: not implemented
    serialize: ->
        # FIXME should this be supported?
        # if so, in which cases?
