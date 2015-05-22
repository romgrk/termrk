
module.exports =
    
    # Shell options
    'shellCommand':
        title:       'Command'
        description: 'Command to call to start the shell. ' +
                     '(auto-detect or executable file)'
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
