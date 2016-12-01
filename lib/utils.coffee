#
# file: utils.coffee
# author: romgrk
# description: atom utils

_    = require 'underscore-plus'
Path = require 'path'
Fs   = require 'fs-plus'
OS   = require 'os'

{$, $$, View} = require 'space-pen'

Utils =
    # Public: get the width of the text with specified font
    getFontWidth: (text, font) ->
        font = font || $('body').css('font')
        o = $('<div>' + text + '</div>')
        .css({
            'position': 'absolute',
            'float': 'left',
            'white-space': 'nowrap',
            'visibility': 'hidden',
            'font': font})
        .appendTo($('body'))
        w = o.width()

        o.remove()

        return w

    # Public: get the height of the text with specified font
    getFontHeight: (text, font) ->
        font = font || $('body').css('font')
        o = $('<div>' + text + '</div>')
        .css({
            'position': 'absolute',
            'float': 'left',
            'white-space': 'nowrap',
            'visibility': 'hidden',
            'font': font})
        .appendTo($('body'))
        h = o.height()
        o.remove()
        return h

    # Path etc
    getHomeDir: ->
        Fs.getHomeDirectory()

    geTmpDir: ->
        OS.tmpdir()

    getProjectDir: ->
        filepath = atom.workspace.getActivePaneItem()?.buffer?.file?.path
        if filepath?
            atom.project.relativizePath(filepath)[0]
        else
            atom.project.getPaths()[0] ? Fs.getHomeDirectory()

    getCurrentDir: ->
        editor = atom.workspace.getActiveTextEditor()
        return Path.dirname editor.getPath() if editor?
        return null

    getCurrentFile: ->
        editor = atom.workspace.getActiveTextEditor()
        return editor.getPath() if editor?
        return null

    resolve: (args...) ->
        args = (Fs.normalize a for a in args)
        Path.resolve args...

module.exports = Utils
