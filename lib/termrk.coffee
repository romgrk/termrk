TermrkView = require './termrk-view'
{CompositeDisposable} = require 'atom'

module.exports = Termrk =
    termrkView: null
    modalPanel: null
    subscriptions: null

    activate: (state) ->
        @termrkView = new TermrkView(state.termrkViewState)
        @modalPanel = atom.workspace.addModalPanel(item: @termrkView.getElement(), visible: false)

        # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
        @subscriptions = new CompositeDisposable

        # Register command that toggles this view
        @subscriptions.add atom.commands.add 'atom-workspace', 'termrk:toggle': => @toggle()

    deactivate: ->
        @modalPanel.destroy()
        @subscriptions.dispose()
        @termrkView.destroy()

    serialize: ->
        termrkViewState: @termrkView.serialize()

    toggle: ->
        console.log 'Termrk was toggled!'

        if @modalPanel.isVisible()
            @modalPanel.hide()
        else
            @modalPanel.show()
