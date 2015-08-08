
{CompositeDisposable} = require 'atom'

Utils  = require './utils'
Font   = Utils.Font
Keymap = Utils.Keymap
Paths  = Utils.Paths

class TermrkConfig

    prefix: null

    # TODO implement this
    restartShell: true

    schema:
        # Shell options
        'shellCommand':
            title:       'Command'
            description: 'Command to call to start the shell. ' +
                         '(auto-detect or executable file)'
            type:        'string'
            default:     'auto-detect'
        'startingDir':
            title:       'Start dir'
            description: 'Dir where the shell should be started.' +
                         '\n*cwd* means current file\'s directory'
            type:        'string'
            default:     'project'
            enum:        ['home', 'project', 'cwd']
        'shellParameters':
            title: 'Shell Parameters'
            description: 'The parameters to pass through when creating the shell'
            type: 'string'
            default: ''
        # 'restartShell':
        #     title: 'Auto-restart'
        #     description: 'Restarts the shell as soon as it is terminated.'
        #     type: 'boolean'
        #     default: 'true'

        # Rendering options
        'defaultHeight':
            title:       'Panel height'
            description: 'Default height of the terminal-panel (in px)'
            # TODO let user choose any css value
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

    constructor: (packageName) ->
        @prefix = packageName + '.'

        for key, value  of @schema
            getKey = @get.bind(@, key)
            setKey = @set.bind(@, key)
            descriptor =
                get: getKey
                set: setKey
            Object.defineProperty this, key, descriptor

    get: (k) ->
        return atom.config.get (@prefix + k)

    set: (k, v) ->
        return atom.config.set (@prefix + k), v

    # Public: observe the given key(s)
    #
    # (key, callback)
    # ({key: callback, ...})
    #
    # Returns [Composite]Disposable
    observe: (key, callback) ->
        if typeof key is 'object'
            disposable = new CompositeDisposable
            for k, fn of key
                disposable.add atom.config.onDidChange(@prefix+k, fn)
        else
            atom.config.onDidChange(@prefix+key, callback)

    # Public: get default system shell
    getDefaultShell: ->
        shell = @get 'shellCommand'
        unless shell is 'auto-detect'
            return shell

        if process.env.SHELL?
            return process.env.SHELL
        else if /win/.test process.platform
            return process.env.TERM ? process.env.COMSPEC ? 'cmd.exe'
        else
            return 'sh'

    # Public: path of the starting dir
    getStartingDir: ->
        switch @get('startingDir')
            when 'home' then Paths.home()
            when 'project' then Paths.project()
            when 'cwd' then atom.workspace.getActiveTextEditor().getURI()
            else process.cwd()

    getDefaultParameters: ->
        parameters = @get('shellParameters')
        args = parameters.split(/\s+/g).filter (arg)-> arg
        args

# TODO fix local name
if atom.packages.getLoadedPackage('termrk')?
    name = 'termrk'
else
    name = 'Termrk'

module.exports = new TermrkConfig(name)
