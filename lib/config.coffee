
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
                         '\n“cwd” means current file\'s directory'
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
        'userCommandsFile':
            title: 'User commands file'
            description: 'File where your commands are stored.\n' +
                         '(relative paths are resolved from: ' +
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
            description: 'Size of the font in terminal'
            type:        'string'
            default:     '14px'
        'fontFamily':
            title:       'Font family'
            type:        'string'
            default:     'Monospace'

        'transitionEasing':
            title:       'Transition easing function'
            description: 'Standard css easings or Tween.js-style.\n' +
                         '(previous value was \'ease-in-out\')'
            type:        'string'
            default:     'easeInExpo'
        'transitionDuration':
            title:       'Transition duration'
            type:        'integer'
            default:     250

        'terminalColors':
            title:       'Terminal colors'
            description: 'The colors to be substituted for the \\x1b[XXm ' +
                         'escape sequences. The first 8 values represent ' +
                         'the dim colors, the next 8 are optional and ' +
                         'represent the bright/bold values and the last 2, ' +
                         'also optional, are the default background and ' +
                         'foreground colors.'
            type:        'array'
            default:     [
                             # dark:
                             '#000000' # black
                             '#cd0000' # red3
                             '#00cd00' # green3
                             '#cdcd00' # yellow3
                             '#0000ee' # blue2
                             '#cd00cd' # magenta3
                             '#00cdcd' # cyan3
                             '#e5e5e5' # gray90
                             # bright:
                             '#7f7f7f' # gray50
                             '#ff0000' # red
                             '#00ff00' # green
                             '#ffff00' # yellow
                             '#5c5cff' # rgb:5c/5c/ff
                             '#ff00ff' # magenta
                             '#00ffff' # cyan
                             '#ffffff' # white
                             # background
                             '#000000'
                             # foreground
                             '#f0f0f0'
                         ]
            items:
                type:    'string'

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
            return disposable
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
        # TODO handle 'quoted' args
        return parameters.split(/\s+/g).filter (arg)-> arg

if atom.packages.getLoadedPackage('termrk')?
    name = 'termrk'
else
    name = 'Termrk'

module.exports = new TermrkConfig(name)
