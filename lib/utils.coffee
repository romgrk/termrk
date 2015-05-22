#
# file: utils.coffee
# author: romgrk
# description: atom utils

_  = require 'underscore-plus'
Fs = require 'fs-plus'
OS = require 'os'

{$, $$, View} = require 'space-pen'

class Config
    prefix: null
    constructor: (prefix) ->
        @prefix = prefix + '.'

    get: (k) ->
        return atom.config.get (@prefix + k)

    set: (k, v) ->
        return atom.config.set (@prefix + k), v

    observe: (key, callback) ->
        if typeof key is 'object'
            atom.config.onDidChange(@prefix+k, fn) for k, fn of key
        else
            atom.config.onDidChange(@prefix+key, callback)

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

    add: (keystrokes, command) ->
        newKeybinding = {
            'atom-workspace': {}
        }
        newKeybinding['atom-workspace'][keystrokes] = command
        atom.keymap.add(__filename, newKeybinding)

    find: (options) ->
        {keys, pack, target, selector, source} = options

        command    = options.command ? options.cmd ? null
        keystrokes = options.keystrokes ? null

        bindings = atom.keymap.getKeyBindings()

        if pack?
            bindings = bindings.filter (b) -> (b.command.match pack+':.*')?
        else if command?
            bindings = bindings.filter (b) -> b.command is command

        if keys?
            bindings = bindings.filter (b) ->
                b.keystrokes.indexOf(keys) == 0
        else if keystrokes?
            keystrokes = @normalizeKeystrokes(keystrokes)
            bindings = bindings.filter (b) ->
                b.keystrokes is keystrokes

        if target?
            candidateBindings = bindings
            bindings = []
            element = target
            while element? and element isnt document
                matchingBindings = candidateBindings
                .filter (binding) -> element.webkitMatchesSelector(binding.selector)
                .sort (a, b) -> a.compare(b)
                bindings.push(matchingBindings...)
                element = element.parentElement

        if selector?
            if _.isRegExp selector
                bindings = bindings.filter (b) -> (b.selector.match(selector))?
            else
                bindings = bindings.filter (b) -> b.selector is selector

        if source?
            bindings = bindings.filter (b) -> b.source is source

        return bindings

    normalizeKeystrokes: (s) ->
        window.require('atom-keymap/lib/helpers').normalizeKeystrokes(s)

Paths =
    home: ->
        Fs.getHomeDirectory()

    tmp: ->
        OS.tmpdir()

    project: ->
        atom.project.getPaths()[0]

module.exports = {Font, Config, Keymap, Paths}
