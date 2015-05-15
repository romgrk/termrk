

ansihtml = require 'ansi-html-stream'
readline = require 'readline'
stream   = require 'stream'

{spawn, exec} = require 'child_process'

module.exports =
class Terminal

    cwd: null

    getLocalEnv: ->
        cmd = 'test -e /etc/profile && source /etc/profile;test -e ~/.profile && source '
        cmd += '~/.profile; node -pe "JSON.stringify(process.env)"'
        exec cmd, (code, stdout, stderr) =>
            try
                @localEnv = JSON.parse stdout
            catch err
                console.error err
