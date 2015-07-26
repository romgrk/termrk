
*Termrk is a terminal implementation based on [term.js][term] and [pty.js][pty] modules by Christopher Jeffrey.*

Spawns default system shell in a sliding panel. Supports multiple terminal sessions.
Basic features include inserting current file path, copy/pasting and setting/fonts config.

*If some feature that you'd like to see isn't implemented, don't hesitate to create a request.*

## Examples

Running basic bash:

![basic](http://raw.githubusercontent.com/romgrk/termrk/master/static/out.gif)
[link](http://raw.githubusercontent.com/romgrk/termrk/master/static/out.gif)

Running vim:

![vim](http://raw.githubusercontent.com/romgrk/termrk/master/static/vim.gif)

## Keybindings

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

Name | Action | Binding (Scope, Key)
--|--|--
`termrk:toggle` | Toggle termrk panel | `atom-workspace`, `alt-space`
`termrk:hide` | Hide termrk panel | none
`termrk:show` | Show termrk panel | none
`termrk:toggle-focus` | Toggle focus of termrk panel | none
`termrk:focus` | Focus termrk panel | none
`termrk:blur` | Blur termrk panel | none
`termrk:create-terminal-current-dir` | Creates session in current file's directory | `atom-workspace`, `ctrl-alt-space`
`termrk:insert-selection` | Inserts current selection in terminal | `atom-workspace`, `ctrl-alt-sphift-space`
`termrk:close-terminal` | Close active terminal session | `.termrk`, `ctrl-escape`
`termrk:insert-filename` | Insert current file's path in terminal | `.termrk`, `% f`

Other:
`termrk:create-terminal`, `termrk:activate-next-terminal`,
`termrk:activate-previous-terminal`

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
