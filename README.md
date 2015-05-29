# *Termrk* - ultimate terminal

Termrk is an implementation of the excellent [term.js][term] and [pty.js][pty] modules by Christopher Jeffrey.
Spawns your default system shell inside atom.

The example below illustrates **termrk** running *zsh*. (see *vim* demo at the end)

![basic](http://raw.githubusercontent.com/romgrk/termrk/master/static/out.gif)
[link](http://raw.githubusercontent.com/romgrk/termrk/master/static/out.gif)

## Install

```
apm install termrk
```

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
  'keystroke': 'native!'
```

## Commands

Name | Action | Binding (Scope, Key)
--|--
`termrk:toggle` | Toggle termrk panel | `atom-workspace`, `alt-space`
`termrk:hide` | Hide termrk panel | none
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

## Tmux-like selection mode

*This feature is from [term.js][term] module. ~~Accurate~~ documentation can be found on the README.md of term.js*

The activation sequence is `ctrl-a [`. Once there, you can move cursor the same way vim's normal-mode does. Press `v` to plant selection tail and start `visual mode`. Move again with normal-mode keys. Press `y` to *y*ank (vim's term for *copy*) selection.
Exit with escape.


### Features
- Toggle panel (slide up)
- Switch between terminals
- Copy/paste from/to terminal
- Set font and color options
- Scrolling

___

## Vim demo

It is not yet perfect but it is capable of running *vim*.
The example below illustrates *vim* running on **termrk**.

![vim](http://raw.githubusercontent.com/romgrk/termrk/master/static/vim.gif)


#### Python error upon installation
If you get a **Python** error, it probably is because the `python` in your path
is a 3.x version of python. Please make sure your path refers to a 2.7 version of python.

[term]: https://github.com/chjj/term.js
[pty]:  https://github.com/chjj/pty.js
