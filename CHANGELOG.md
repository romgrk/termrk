## 0.1.25
* user commands: see README.md
* command run-current-file now supports shebang (#!)
* setting useDefaultKeymap: toggles termrk default Keybindings
* setting restartShell: auto-restart shell
* fixed: scroll terminal

## 0.1.24
* add command `termrk:run-current-file`

## 0.1.18
* In config, setting startingDir to `cwd` spawns sessions in current file's
  directory
* Terminal gains focus after text has been pasted

## 0.1.16
* disable screenKeys feature

## 0.1.15
* **Note:** `escape` has been unbound of `termrk:hide`, because
  it is an important key in terminal. If you still want it to
  act as before, map it in your keymap.cson
  ```
  '.termrk':
    'escape': 'termrk:hide'
  ```
* make text inside terminal selectable
* make selection-style use `@background-color-selected`, or default as white
* insert '%' if it is not followed by 'f'

## 0.1.13
* fix: % catched by command

## 0.1.12
* ctrl-alt-shift-space inserts current selection in terminal (command: `termrk:insert-selection`)
* `shift-backspace` and `ctrl-x` now treated as `native!`

## 0.1.11
* Terminal now supports scrolling

## 0.1.10
* Add % binding: insert current file name in terminal

## 0.1.9
* Fix paste issue
* Add resize to panel

## 0.1.7
* Paste to terminal is supported, with command 'core:paste'

## 0.1.5
* Keybindings are consistent

## 0.1.0 - First Release
* Every feature added
* Every bug fixed
