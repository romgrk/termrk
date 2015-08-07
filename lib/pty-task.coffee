# lifted and modified from term2/pty.coffee to solve: https://github.com/romgrk/termrk/issues/28

pty = require('pty.js')

module.exports = (ptyCwd, args, options) ->
    callback = @async()
    ptyProcess = pty.fork ptyCwd, args, options

    ptyProcess.on 'data', (data) -> emit('data', data)
    ptyProcess.on 'exit', ->
        emit('exit')
        callback()

    process.on 'message', ({event, cols, rows, text}={}) ->
        switch event
            when 'resize' then ptyProcess.resize(cols, rows)
            when 'input' then ptyProcess.write(text)
