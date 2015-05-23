# *Termrk* - ultimate terminal

Termrk is an implementation of the excellent [term.js][term] and [pty.js][pty] modules by Christopher Jeffrey.
Spawns your default system shell inside atom.

*Not yet tested on Windows/OSX, feedback is welcome.*

The example below illustrates **termrk** running *zsh*. (see *vim* demo at the end)

![Basic demo of termrk][basic]

## Install
Due to a highly platform variable dependency, the following issues can arise.

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


### Features
- Toggle panel (slide up)
- Switch between terminals
- Paste to terminal
- Set font options

___

## Vim demo

It is not yet perfect but it is capable of running *vim*.
The example below illustrates *vim* running on **termrk**.

![Demo of vim][vim]


#### Python error upon installation
If you get a **Python** error, it probably is because the `python` in your path
is a 3.x version of python. Please make sure your path refers to a 2.7 version of python.


[term]: https://github.com/chjj/term.js
[pty]:  https://github.com/chjj/pty.js


[basic]: http://raw.githubusercontent.com/romgrk/termrk/master/static/out.gif
[vim]:   http://raw.githubusercontent.com/romgrk/termrk/master/static/vim.gif
