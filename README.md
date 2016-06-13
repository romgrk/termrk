# Termrk
> Sliding terminal panel for Atom.

There are various implementations of terminals for Atom; each with their own
vision/perspective.  The main focus of this one is to have a slick, quickly
accessible terminal panel: handy when you need it; out-of-the way when you
don't.
It slides in and out with a single keystroke, mapped to `alt-space` by
default. Efficient and simple.

<!--FIXME TOC doesnt seem to work on atom.io ¡gfm! -->
1. [Overview](#overview)
2. [Keybindings](#--keybindings)
3. [Commands](#commands)
4. [User-commands](#user-commands)
5. [Styling](#styling)
6. [Credits](#credits)
7. [License](#license)

## Overview

![Termrk Screenshot](https://github.com/romgrk/termrk/blob/master/static/out.gif?raw=true)

**Currently implemented:**
 - multiple terminal sessions
 - user defined commands (→ user defined *atom-commands*)
 - running current file in terminal 
   (supports `.js`, `.node`, `.coffee`, `.py` and shebang-notation―`#!`)
 - inserting selection to/from the buffer
 - inserting current file/directory path
 - color/font styling

*If some feature that you'd like to see isn't implemented, don't hesitate to create a request.*

#### Demo: running *vim* inside *termrk* inside *atom*

![vim demo](https://github.com/romgrk/termrk/blob/master/static/vim.gif?raw=true)

## ⌨  Keybindings

Designed around the `alt-space` keystroke really. It is often unmapped,  and
very easy to access.

**→ workspace**

 - `alt-space`:      toggle terminal panel
 - `ctrl-alt-space`: create terminal in current file's dir
 - `ctrl-alt-shift-space`: insert current selection in active terminal

**→ inside terminal**

 - `ctrl-escape`:    close current terminal
 - `ctrl-space`:     create terminal
 - `ctrl-tab`:       activate next terminal
 - `ctrl-shift-tab`: activate previous terminal


**Note**: if a `keystroke` is catched by an atom-command but you need it inside terminal, add the following code to you `keymap.cson`.

```coffee
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

## User-commands

User commands are defined in the file `$ATOM_HOME/userCommands.cson`.
(file path can be configured *via* Atom Settings)

Commands have this format:
```coffee
'echofile':
  command: 'echo The current file is $FILE'
```
The previous command description would be mapped to `'termrk:command-echofile'`,
and calling that command would run `'echo The current file is $FILE'` in 
terminal.

Other examples:
```coffee
'shellreplace':
  'command': 'gnome-shell --replace --display :0'

'coffeerun':
  'command': 'coffee $FILE'

'npmyes':
  'command': 'cd $DIR && npm init --yes'

# ...
```

Defined variables:

| Name       | Value                                           |
| ----       | -----                                           |
| `$FILE`    | `atom.workspace.getActiveTextEditor().getURI()` |
| `$DIR`     | `path.dirname $FILE`                            |
| `$PROJECT` | `atom.project.getPaths()[0]`                    |

The variables aren´t really defined in the environment — using plain `String.replace`.

## Styling
(through less/css)

Example for black text on white bg, and blue cursor-bg.

```css
.termrk .terminal {
    color: black;
    background-color: blue;
}

.termrk .terminal-cursor {
    color: black;
    background-color: white;
}
```

## Credits

Termrk is a terminal implementation based on [term.js][term] and [pty.js][pty] 
modules by Christopher Jeffrey.

Atom is a text-editor developped by github etc. etc....

## License

> Same as JSON


--------------------------------------------------------

[term]: https://github.com/chjj/term.js
[pty]:  https://github.com/chjj/pty.js

<!-- lang: coffee -->
