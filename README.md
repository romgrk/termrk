# *Termrk* - ultimate terminal

Termrk is an implementation of the excellent [term.js][term] and [pty.js][pty] modules by Christopher Jeffrey.
Spawns your default system shell inside atom.

*Not yet tested on Windows/OSX, feedback is welcome.*

The example below illustrates **termrk** running *zsh*. (see *vim* demo at the end)

![Basic demo of termrk][basic]

## Install

You might need to rebuild the term.js/pty.js modules. It is very simple.
```
cd $ATOM_HOME/packages/termrk
apm rebuild
```

## Keybindings

Because of the way term.js handles keystrokes, some keybindings aren't listed in the usual way.

#### workspace
- `alt-space` : toggle terminal panel

#### inside terminal

- `escape` : hide terminal panel
- `ctrl-space` : create terminal
- `ctrl-tab` : activate next terminal
- `ctrl-shift-tab` : activate previous terminal


### Features
- Toggle panel
- Toggle between terminals

### Known bugs
- Keybindings don't work well while the terminal is focused.

___

## Vim demo

It is not yet perfect but it is capable of running *vim*.
The example below illustrates *vim* running on **termrk**.

![Demo of vim][vim]




[term]: https://github.com/chjj/term.js
[pty]:  https://github.com/chjj/pty.js


[basic]: http://raw.githubusercontent.com/romgrk/termrk/master/static/out.gif
[vim]:   http://raw.githubusercontent.com/romgrk/termrk/master/static/vim.gif
