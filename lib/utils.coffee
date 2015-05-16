
{$, $$, View} = require 'space-pen'

Font =
    # Public: get the width of the text with specified font
    getWidth: (text, font) ->
        font = font || $('body').css('font')
        o = $('<div>' + text + '</div>')
        .css({
            'position': 'absolute',
            'float': 'left',
            'white-space': 'nowrap',
            'visibility': 'hidden',
            'font': font})
        .appendTo($('body'))
        w = o.width();

        o.remove();

        return w

    # Public: get the height of the text with specified font
    getHeight: (text, font) ->
        font = font || $('body').css('font')
        o = $('<div>' + text + '</div>')
        .css({
            'position': 'absolute',
            'float': 'left',
            'white-space': 'nowrap',
            'visibility': 'hidden',
            'font': font})
        .appendTo($('body'))
        h = o.height();

        o.remove();

        return h

module.exports = {Font}
