*Termrk is a terminal implementation based on [term.js][term] and [pty.js][pty] modules by Christopher Jeffrey.*

Spawns default system shell in a sliding panel.
Basic features include:
- user-defined commands
- multiple terminal sessions
- running current file in terminal [1]
- inserting selection
- inserting current file path
- color/font styling

[1] currently, only supports .js, .node, .coffee, .py and `#!`

*If some feature that you'd like to see isn't implemented, don't hesitate to create a request.*

## Examples

Running basic bash:

![basic](http://raw.githubusercontent.com/romgrk/termrk/master/static/out.gif)
[link](http://raw.githubusercontent.com/romgrk/termrk/master/static/out.gif)

Running vim:

![vim](http://raw.githubusercontent.com/romgrk/termrk/master/static/vim.gif)
[link](http://raw.githubusercontent.com/romgrk/termrk/master/static/vim.gif)

## Keybindings

*Disable all default keybindings in SettingsView >> Termrk >> Default keymap*

#### workspace

- `alt-space`:      toggle terminal panel
- `ctrl-alt-space`: create terminal in current file's dir
- `ctrl-alt-shift-space`: insert current selection in active terminal

#### inside terminal

- `ctrl-escape`:    close current terminal
- `ctrl-space`:     create terminal
- `ctrl-tab`:       activate next terminal
- `ctrl-shift-tab`: activate previous terminal

**Note**: if a `keystroke` is catched by an atom-command but you need it inside terminal, add the following code to you `keymap.cson`.

```
'.termrk':
  'KEYSTROKE_TO_CATCH': 'native!'
```

## Commands

| Name                                 | Action                                      | Scope            | Keybinding              |
| ----                                 | ----                                        | ----             | ----                    |
| `termrk:toggle`                      | Toggle termrk panel                         | `atom-workspace` | `alt-space`             |
| `termrk:hide`                        | Hide termrk panel                           | `atom-workspace` |                         |
| `termrk:show`                        | Show termrk panel                           | `atom-workspace` |                         |
| `termrk:toggle-focus`                | Toggle focus of termrk panel                | `atom-workspace` |                         |
| `termrk:focus`                       | Focus termrk panel                          | `atom-workspace` |                         |
| `termrk:blur`                        | Blur termrk panel                           | `atom-workspace` |                         |
| `termrk:create-terminal`             | Creates new session                         | `atom-workspace` | `ctrl-space`            |
| `termrk:create-terminal-current-dir` | Creates session in current file's directory | `atom-workspace` | `ctrl-alt-space`        |
| `termrk:close-terminal`              | Close active terminal session               | `.termrk`        | `ctrl-escape`           |
| `termrk:insert-selection`            | Inserts current selection in terminal       | `atom-workspace` | `ctrl-alt-sphift-space` |
| `termrk:insert-filename`             | Insert current file's path in terminal      | `.termrk`        | `% f`                   |
| `termrk:run-current-file`            | Runs current file in terminal               | `atom-workspace` |                         |
| `termrk:create-terminal`             | Creates a terminal-session                  | `atom-workspace` |                         |
| `termrk:activate-next-terminal`      | Cycles forward terminal-sessions            | `atom-workspace` |                         |
| `termrk:activate-previous-terminal`  | Cycles backward terminal-sessions           | `atom-workspace` |                         |

# User commands

User commands are defined in the file `$ATOM_HOME/userCommands.cson`.
(file path can be configured *via* Atom Settings)

Commands have this format:

```coffeescript
'echofile':
  command: 'echo The current file is $FILE'
```
The previous command description would be mapped to `'termrk:command-echofile'`.

Defined variables:

| name       | value                                           |
| --         | --                                              |
| `$FILE`    | `atom.workspace.getActiveTextEditor().getURI()` |
| `$DIR`     | `path.dirname $FILE`                            |
| `$PROJECT` | `atom.project.getPaths()[0]`                    |

The variables aren´t really defined in the environment — using plain `String.replace`.

## Styling

Example, for black text on white bg, and blue cursor-bg.

```less
.termrk .terminal {
    color: black;
    background-color: blue;
}

.termrk .terminal-cursor {
    color: black;
    background-color: white;
}
```

[term]: https://github.com/chjj/term.js
[pty]:  https://github.com/chjj/pty.js
