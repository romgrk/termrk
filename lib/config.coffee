
Utils  = require './utils'
Config = Utils.Config
Font   = Utils.Font
Keymap = Utils.Keymap
Paths  = Utils.Paths

class TermrkConfig extends Config
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
            description: 'Dir where the shell should be started.'
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

# Test package name, apm is case-sensitive sometimes >> TODO create issue on APM
if atom.packages.getLoadedPackage('termrk')?
    name = 'termrk'
else
    name = 'Termrk'

module.exports = new TermrkConfig(name)
