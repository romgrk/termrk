# current

# issues
* ptyjs resize
* Termrk config entry => see SettingsView?
* scroll

# tasks
* reimplement config with Object.defineProp
* enhance: add user commands
* enhance: option: startup script
* enhance: run current file in REPL
* enhance: open in different position
* enhance: pipe command output to editor

# ideas/projects
* retrieve terminal-session cwd
  - in Linux/OSX: `lsof -a -p PID -d cwd -F n`
  - in Windows: ?


# fixed/changed
* *untested* issue: scroll throw Undefined Error
