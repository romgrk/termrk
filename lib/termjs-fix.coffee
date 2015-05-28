

termjs = require('term.js')

class Terminal extends termjs.Terminal

    @insertStyle: -> return

    @bindKeys: ->
        document.addEventListener 'mousedown', (ev) ->
            unless Terminal.focus
                return
            el = ev.target || ev.srcElement
            return unless el?
            while el
                if (el is Terminal.focus.element)
                    return
                el = el.parentNode
            Terminal.focus.blur()

    focus: ->
        super()
        return true

    blur: ->
        super()
        return true

    resize: (width, height) ->
        # var line , el , i , j , ch

        width = 1 if width < 1
        height = 1 if height < 1

        # // resize cols
        j = @cols
        if j < width
            ch = [@defAttr, ' '] # // does xterm use the default attr?
            i = @lines.length
            while (i--)
                while (@lines[i].length < width)
                    @lines[i].push(ch)
        else if (j > width)
            i = @lines.length
            while (i--)
                while (@lines[i].length > width)
                    @lines[i].pop()

        @setupStops(j)
        @cols = width

        # // resize rows
        j = @rows
        if (j < height)
            el = @element
            while (j++ < height)
                if (@lines.length < height + @ybase)
                    @lines.push(@blankLine())
                if (@children.length < height)
                    line = @document.createElement('div')
                    el.appendChild(line)
                    @children.push(line)
        else if (j > height)

            diff = @rows - height
            console.log @rows, height, diff
            console.log @children, @element.children
            # for k in [0..diff - 1]
                # el = @children.unshift()
                # @element.children[0].remove()
                # el?.parentNode?.removeChild(el)
            while (j-- > height)
                if (@children.length > height)
                    el = @children.shift()
                    console.log j, 'el', el
                    if (!el)
                        continue
                    else
                        el.parentNode.removeChild(el)

        @rows = height

        # // make sure the cursor stays on screen
        if (@y >= height)
            @y = height - 1
        if (@x >= width)
            @x = width - 1

        @scrollTop = 0
        @scrollBottom = @rows - 1

        @refresh(0, @rows - 1)

        # // it's a real nightmare trying
        # // to resize the original
        # // screen buffer. just set it
        # // to null for now.
        @normal = null

module.exports = Terminal
