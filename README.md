# *Termrk* - ultimate terminal

Termrk is an implementation of the excellent [term.js][term] and [pty.js][pty] modules by Christopher Jeffrey.
Spawns your default system shell inside atom.

*Not yet tested on Windows/OSX, feedback is welcome.*

The example below illustrates **termrk** running *zsh*. (see *vim* demo at the end)

![basic](http://raw.githubusercontent.com/romgrk/termrk/master/static/out.gif)

## Install

```
apm install termrk
```

## Keybindings

#### workspace

- `alt-space`:      toggle terminal panel
- `ctrl-alt-space`: create terminal in current file's dir

#### inside terminal

- `escape`:         hide panel
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

Name | Action | Scope, Key
--|--
`termrk:hide` | Hide termrk panel | `.termrk`, `escape`

## Selection

*This feature is from [term.js][term] module. ~~Accurate~~ documentation can be found on the README.md of term.js*

The activation sequence is `ctrl-a [`. Once there, you can move cursor the same way vim's normal-mode does. Press `v` to plant selection tail and start `visual mode`. Move again with normal-mode keys. Press `y` to *y*ank (vim's term for *copy*) selection.

**Important note**: to get out of the `ctrl-a [` mode, the key is `escape`. However, it is currently mapped to `termrk:hide`. Unmap it before using `ctrl-a [` mode.
I'll check if I can add an escape escape key.


### Features
- Toggle panel (slide up)
- Switch between terminals
- Paste to terminal
- Set font options
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
