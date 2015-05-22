#
# file: utils.coffee
# author: romgrk
# description: atom utils

{$, $$, View} = require 'space-pen'

KeymapHelpers = window.require 'atom-keymap/lib/helpers'

class Config
    prefix: null
    constructor: (@prefix) ->

    get: (k) ->
        return atom.config.get (@prefix + '.' + k)

    set: (k, v) ->
        return atom.config.set (@prefix + '.' + k), v

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

Keymap =

    helpers: KeymapHelpers

    add: (keystrokes, command) ->
        newKeybinding = {
            'atom-workspace': {}
        }
        newKeybinding['atom-workspace'][keystrokes] = command
        atom.keymap.add(__filename, newKeybinding)

    find: (options) ->
        return unless options?


module.exports = {Font, Config, Keymap}

console.log Keymap.add 'ctrl-@', 'nop-long'
