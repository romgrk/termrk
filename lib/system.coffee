
_     = require 'underscore-plus'
Fs    = require 'fs-plus'
FsEx  = require 'fs-extra'
Path  = require 'path'
Glob  = require 'glob'
Trash = require 'trash'

################################################################################
# Section: helpers
################################################################################


################################################################################
# Section: Methods
################################################################################


################################################################################
# Section: Classes
################################################################################

# Small file model
class Fyler
    rel:         (p) -> Path.relative(@path, p)
    exp:         (p) -> if Fs.existsSync(p) then Fs.realpathSync(p) else p
    resolve:     (p...) ->
        args = @normalize(p...)
        res = Path.resolve(@dir, args)
        @exp(res)
    normalize:   (p...) -> _.map(p, Fs.normalize)
    constructor: (options={}) ->
        @path     = options.path    ? null
        if @path? and tokens = Path.parse(@path)
            @root = tokens.root ? null
            @dir  = tokens.dir ? null
            @base = tokens.base ? null
            @ext  = tokens.ext ? null
            @name = tokens.name ? null
        @input    = options.input   ? null
        @isFile   = options.isFile  ? null
        @isDir    = options.isDir   ? null
        @isLink   = options.isLink  ? null
        @exists   = options.exists  ? null
        @relative = options.relative? null
        @cwd      = options.cwd     ? @dir ? null

class SysError extends Error
    @constructor: (args...) ->
        super()
        @message = args.join("\n")

class System

    @resolve: (args...) ->
        for p, i in args
            args[i] = Fs.normalize(p)
        p = Path.resolve(args...)
        return if Fs.existsSync(p) then Fs.realpathSync(p) else p

    @normalize: (path) -> Fs.normalize(path)

    @WINDOWS_PATH: ///
    ^(?:(?:[a-z]:|\\\\[a-z0-9_.$●-]+\\[a-z0-9_.$●-]+)\\|\\?[^\\/:*?"<>|↵
    \r\n]+\\?)(?:[^\\/:*?"<>|\r\n]+\\)*[^\\/:*?"<>|\r\n]*$
    ///

    @UNIX_PATH: ///
    \(                         # Either
    [^\0 !$`&*()+]              # A normal (non-special) character
    \|                          # Or
    \\\(\ |\!|\$|\`|\&|\*|\(|\)|\+\)   # An escaped special character
    \)\+                       # Repeated >= 1 times
    ///

    HIDDEN_FILE: /\/\.[^\/]+$/

    # Public: current dir
    cwd: null

    constructor: (@cwd) ->
        @cwd ?= process.cwd()

    ############################################################################
    # Section: Path/FileSystem utilities (static)
    ############################################################################

    join: (paths...) ->
        paths = for p in paths
            Fs.normalize p
        Path.join

    resolve: (args...) ->
        for p, i in args
            args[i] = Fs.normalize(p)
        args.unshift(@cwd)
        p = Path.resolve(args...)
        return if @exists(p) then @real(p) else p

    real: (path) -> Fs.realpathSync path

    abs:  (path) ->
        return path if @isAbs path
        @resolve(@cwd, path)

    relative:  (from, to) -> Path.relative(from, to)
    rel:       (from, to) -> Path.relative(from, to)

    dirname:   (path) -> Path.dirname path
    dir:       (path) -> @dirname path

    basename:  (path) -> Path.basename path
    base:      (path) -> @basename path

    normalize: (path) -> Fs.normalize path
    norm:      (path) -> @normalize path

    name:      (path) -> Path.parse(path).name
    ext:       (path) -> Path.extname(path)

    root: -> Path.parse(process.cwd()).root

    exists:   (path) -> Fs.existsSync(path)
    isDir:    (path) -> Fs.isDirectorySync @resolve(path)
    isNotDir: (path) -> not @isDir(path)
    isFile:   (path) -> Fs.isFileSync @resolve(path)
    isLink:   (path) -> Fs.isSymbolicLinkSync @resolve(path)
    isAbs:    (path) -> Path.isAbsolute(path)
    isRel:    (path) -> (not Path.isAbsolute(path))
    isPath:   (path) ->
        console.warn 'Using unsafe method isPath()'
        path.match(System.UNIX_PATH)? or path.match(System.WINDOWS_PATH)?

    list:      (path, options={}) ->
        files   = options.files ? true
        dirs    = options.dirs ? true
        visible = options.visible ? true
        hidden  = options.hidden ? true
        base    = options.base ? false

        paths = Fs.listSync(@abs path)
        console.log paths

        unless files
            paths = _.filter(paths, (p) => not @isFile p)

        unless dirs
            paths = _.filter(paths, (p) => not @isDir p)

        unless visible
            paths = _.filter(paths, (p) -> p.match(System.HIDDEN_FILE))

        unless hidden
            paths = _.filter(paths, (p) -> not p.match(System.HIDDEN_FILE))

        if base
            paths = _.map(paths, Path.basename)

        return paths

    ls: (path, options={}) ->
        options.files   = options.files ? true
        options.dirs    = options.dirs ? true
        options.visible = options.visible ? true
        options.hidden  = options.hidden ? false
        options.base    = options.base ? true

        return @list(path, options)

    la: (path, options={}) ->
        options.files   = options.files ? true
        options.dirs    = options.dirs ? true
        options.visible = options.visible ? true
        options.hidden  = options.hidden ? true
        options.base    = options.base ? false

        list = {}
        _.each @list(path, options), (file) =>
            details = @details(file)
            list[details.basename] = details

        return list

    tree: (path) -> Fs.listTreeSync path

    # Public: return a list of file matched by the pattern
    #
    # 1.
    # * `pattern`   - pattern; cwd is process.cwd()
    #
    # 2.
    # * `cwd`       - path to the cwd
    # * `pattern`   - pattern
    #
    # Returns nothing.
    glob:    (one, two=null) ->
        if one? and _.isString(one) and (_.isString(two) or (not two?))
            if _.isString(two)
                pattern = two
                cwd = one
            else
                pattern = one
                cwd = process.cwd()
            files = Glob.sync(pattern, {cwd: cwd})
            return _.map files, (file) ->
                Path.resolve(cwd, file)

        else if _.isArray(one)
            list = []
            for arg in one
                for gra in @glob(arg, two)
                    list.push(gra)
            return list
        else if _.isArray(two)
            list = []
            for arg in two
                for gra in @glob(one, arg)
                    list.push(gra)
            return list
        else
            console.error new SysError "idk. meh."


    # Public: information
    f: (path) ->
        return new Fyler {
            path:     @resolve(path)
            input:    path
            isFile:   Fs.isFileSync(path)
            isDir:    Fs.isDirectorySync(path)
            isLink:   Fs.isSymbolicLinkSync(path)
            exists:   @exists(path)
        }



    # Public: information
    details: (path) ->
        _.extend Path.parse(path),
            path:   path
            exists: Fs.exists(path)
            isFile: Fs.isFileSync(path)
            isDir:  Fs.isDirectorySync(path)
            isLink: Fs.isSymbolicLinkSync(path)

    unique: (path) ->
        unless @exists(path)
            return path
        unless @isAbs(path)
            path = @resolve path

        details       = @details path
        base          = @base path
        numberedRegex = /(.*)\((\d+)\)(\.[\w\d]+)?$/

        if match = base.match(numberedRegex)
            console.log match
            num = parseInt(match[2]) + 1
            newName = match[1] + "(#{num})"
            newName += match[3] if match[3]?
        else
            newName = details.name + "(1)" + details.ext

        newPath = @resolve(details.dir, newName)
        return @unique newPath


    ############################################################################
    # Section: Operators
    ############################################################################

    open: (paths) ->
        paths = _toArray(paths, @)
        atom.workspace.open(p) for p in paths


    # Public: retrives information about an mv/cp operation
    #
    # f as f
    # f in d
    # d in d
    # d as d
    # * in d
    #
    # example: mv {dir:'/home/user', }, (dir:'/abs', name:'bar.txt')
    #
    # Returns nothign.
    operation: (source, target, overwrite=true) ->
        unless source? and target?
            throw new Error 'operation: undefined argument(s)'

        recursiveCallback = (sources) =>
            operations = []
            for s in sources
                op = @operation(s, target)
                operations.push(op) unless op is null
            return operations

        if _.isArray(source)
            return recursiveCallback(source)

        if typeof source is 'string'
            if @exists(source) # source is a path
                input = @f source

            else #try for glob pattern
                files = @glob(source)
                unless files.length > 0
                    throw new Error "Source isn't valid {String} '#{source}'"
                else
                    return recursiveCallback(files)

        if typeof source is 'object'
            hasInfo = source.path? or source.dir? or
                source.file? or source.name?

            if hasInfo
                input = @f(
                    source.path ? source.dir ? source.file ? source.name)
            else
                throw new Error "operation: #{source}"

        if typeof target is 'object'         # TARGET

            if target.dir? and target.name?
                out =
                    dir: @abs(target.dir)   # output to dir
                    base: target.name       # rename to name
            else if target.dir?
                out =
                    dir: @abs(target.dir)   # output to dir
                    base: input.base        # name stays the same
            else if target.name?
                out =
                    dir: input.dir          # output to dir
                    base: target.name       # rename
            else
                console.error target
                throw new Error "Couldnt parse target"

        if typeof target is 'string'
            out = @f(target)
            if out.isFile and input.isDir
                throw new Error "copy: Cant overwrite file with dir."

        type = (x) ->
            return 'dir' if x.isDir
            return 'file' if x.isFile
            return 'unknown'

        return {
            overwrite: true;
            execute:   true

            source:    source
            target:    target

            input: input
            output: out

            oldpath: input.path
            newpath: out.path
            temppath: Path.resolve(out.dir, input.base)

            type: type(input)
        }
        #end

    # Public: moves files and dirs
    #
    # 1. * source - filename (must exist)
    #    * target - dirname (must exist)
    #           source is mv recursively in target
    #
    # 2. * source - dirname (must exist)
    #    * target - dirname (must exist)
    #           source is mv recursively in target
    #
    # 3. * source - list of paths (must exist)
    #    * target - dirname (must exist)
    #           sources are mv recursively in target
    #
    # Returns nothing.
    move: (source, target) ->

        operations = @operation(source, target)
        unless _.isArray(operations)
            operations = [operations]

        for op in operations
            unless op.input.exists
                throw new Error "Input path doesnt exist"
            Fs.moveSync(op.input.path, op.temppath)
            @rename(op.temppath, op.newpath)

    # Public: copy files and dirs
    #
    # 1. * source - filename (must exist)
    #    * target - dirname (must exist)
    #           source is mv recursively in target
    #
    # 2. * source - dirname (must exist)
    #    * target - dirname (must exist)
    #           source is mv recursively in target
    #
    # 3. * source - list of paths (must exist)
    #    * target - dirname (must exist)
    #           sources are mv recursively in target
    #
    # Returns nothing.
    # TODO option to create target
    copy: (source, target) ->
        unless source? and target?
            throw new Error('copy: No entries on which to perform')

        operations = @operation(source, target)
        unless _.isArray(operations)
            operations = [operations]

        for op in operations
            console.log op
            if op.input.isDir
                @copyDir op.oldpath, op.newpath
            else if op.input.isFile
                @copyFile op.oldpath, op.newpath
            else
                throw new Error "copy: nothing to do with operation #{op}"
    #end

    # Public: copies a single file, both paths are filenames
    #
    # Returns a {Boolean} on success
    copyFile: (oldpath, newpath, overwrite=true) ->
        rdStream = Fs.createReadStream oldpath
        wrStream = Fs.createWriteStream newpath
        rdStream.pipe wrStream
        return null

    copyDir: (oldpath, newpath) ->
        Fs.copySync(oldpath, newpath)


    rename: (oldpath, newpath, overwrite=true) ->
        unless @exists oldpath
            throw new Error("Path doesnt exit: #{oldpath}")

        if @exists(newpath) and (not overwrite)
            throw new Error("Path already exists #{newpath}")

        # if newpath is a filename, buid the path from oldpath.dir
        unless @isAbs(newpath)
            newpath = @resolve(@dirname(oldpath), newpath)

        Fs.renameSync(oldpath, newpath)

    # File-specific

    write: (filename, content, overwrite=true) ->
        if @exists(filename) and (not overwrite)
            throw new SysError("Path already exists: #{filename}")

        Fs.writeFileSync(filename, content)

    append: (filename, content) ->
        Fs.appendFileSync(filename, content)

    read: (filename) ->
        Fs.readFileSync(filename)

    touch: (filename) ->
        unless @exists(filename)
            Fs.closeSync Fs.openSync(filename, 'w')

    # Dir-specific

    # Public: makea dir(s)
    #
    # * path - path to the new directory
    #
    # Returns nothing.
    mkdir: (path, recursive=true) ->
        if _.isArray path
            @mkdir p for p in path

        if (not recursive)
            Fs.mkdirSync(path)
        else
            Fs.makeTreeSync(path)

    rm: (paths, moveToTrash=true) ->
        if moveToTrash
            @trash paths
        else
            @delete paths
            # @trash paths
            console.warn "delete operation deactivated"

    delete: (paths) ->
        unless _.isArray paths
            paths = [paths]

         paths.forEach (path) ->
            try FsEx.deleteSync(path)
            catch err
                console.error err.message
                console.error err.printStackTrace()

    trash: (paths) ->
        unless _.isArray paths
            paths = [paths]
        try
            Trash(paths, (e) -> throw e)
        catch err
            console.error err.message
            console.error err.printStackTrace()


module.exports = {System, Fyler}
