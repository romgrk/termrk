

{Terminal} = require('term.js')

# Clear term.js style injection.
if Terminal.insertStyle?
    Terminal.insertStyle = () -> return


module.exports = Terminal
