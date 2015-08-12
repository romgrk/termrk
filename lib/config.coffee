
{CompositeDisposable} = require 'atom'

Utils  = require './utils'

class TermrkConfig

    prefix: null

    schema:
        # Shell options
        'shellCommand':
            title:       'Shell'
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
        'restartShell':
            title: 'Auto-restart'
            description: 'Restarts the shell as soon as it is terminated.'
            type: 'boolean'
            default: 'true'

        # User options
        'useDefaultKeymap':
            title:       'Default keymap'
            description: 'Use keymap provided by Termrk package'
            type:        'boolean'
            default:     'true'
        'userCommandsFile':
            title: 'User commands file'
            description: 'File where your commands are stored.\n' +
                         '(absolute or relative to ' +
                         atom.getConfigDirPath() + ')'
            type: 'string'
            default: 'userCommands.cson'


        # Rendering options
        'defaultHeight':
            title:       'Panel height'
            description: 'Height of the terminal-panel (in px)'
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
            when 'home' then Utils.getHomeDir()
            when 'project' then Utils.getProjectDir()
            when 'cwd' then Utils.getCurrentDir()
            else process.cwd()

    getDefaultParameters: ->
        parameters = @get('shellParameters')
        return parameters.split(/\s+/g).filter (arg)-> arg

if atom.packages.getLoadedPackage('termrk')?
    name = 'termrk'
else
    name = 'Termrk'

module.exports = new TermrkConfig(name)
