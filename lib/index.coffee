sysPath = require('path')
os = require('os')
util = require('util')
progeny = require('progeny')
libsass = require('node-sass')
fs =  require('fs')
colors = require('colors')
mkdirp = require('mkdirp')
sassRe = /\.s[ac]ss$/

extend = (object, source) ->
  for key of source
    object[key] = source[key]
  object

class ThemesCSSCompiler
  brunchPlugin: yes
  type: 'stylesheet'
  extension: 'scss'
  pattern: /\.s[ac]ss$/

  constructor: (@cfg) ->
    @rootPath = @cfg.paths.root;
    @optimize = @cfg.optimize
    @config = (@cfg.plugins && @cfg.plugins.themes_compiler) || {};
    @baseDir = if @config.options and @config.options.baseDir then @config.options.baseDir else 'base'
    @sassDir = if @config.options and @config.options.sassDir then @config.options.sassDir else 'sass'
    @absRootDir = sysPath.join sysPath.resolve(), 'app'
    @outPath = sysPath.resolve(@cfg.paths.public)
    if @config.options and @config.options.includePaths
      @includePaths = @config.options.includePaths

    @themeDirs = @_getDirectories @absRootDir
    @themeSassFiles = {}

    @themeDirs.forEach (name) =>
      themeSassDir = sysPath.join @absRootDir, name , @sassDir
      files = @_findFilesInDir(themeSassDir, name ,'.scss')
      @themeSassFiles[name] = files

#    console.log @themeSassFiles

    @getDependencies = progeny(
      rootPath: @rootPath
      altPaths: @includePaths
      reverseArgs: true)

    @seekCompass = progeny(
      rootPath: @rootPath,
      exclusion: '',
      potentialDeps: true
    )

  _findFilesInDir: (startPath, theme, filter) =>
    results = {}
    if !fs.existsSync(startPath)
      console.log 'no dir ', startPath
      return
    files = fs.readdirSync(startPath)
    i = 0
    while i < files.length
      filename = sysPath.join(startPath, files[i])
      stat = fs.lstatSync(filename)
      if stat.isDirectory()
#        results = results.concat(@_findFilesInDir(filename, theme, filter))
        results = extend(results, @_findFilesInDir(filename, theme, filter))
        #recurse
      else if filename.indexOf(filter) >= 0
        #console.log '-- found: ', filename
        #old filename.replace(sysPath.join(@absRootDir, theme , @sassDir), '')
        #sysPath.relative(sysPath.join(@absRootDir, theme, @sassDir), filename).replace(sassRe, '').replace('_','')
        importPath = filename.replace('_', '').replace(sassRe,'')
        results[importPath] = filename
      i++
    results

  _getDirectories: (path) ->
    fs.readdirSync(path).filter (file) ->
      fs.statSync(sysPath.join(path, file)).isDirectory()

  _getIncludePaths: (path) =>
    includePaths = [
      @rootPath
      sysPath.dirname(path)
    ]
    if Array.isArray(@includePaths)
      includePaths = includePaths.concat(@includePaths)
    includePaths

  _urlImporter: (url, prev, theme)=>
#    console.log url, '<-', prev
    #Convert import urls to absolute paths and match against theme for substitution
    getAbsImport = (imp_url, prev_url) =>
      rootSassDir = sysPath.join(@absRootDir, theme, @sassDir)
      if prev_url != "stdin"
        import_url = sysPath.dirname(sysPath.join(rootSassDir, prev_url.replace(/app\/?base\/?sass\/?/,'')))
        import_url = sysPath.join(import_url,imp_url)
        match_file = @themeSassFiles[theme].hasOwnProperty(import_url)
      else
        import_url = sysPath.join(rootSassDir, imp_url.replace(/app\/?base\/?sass\/?/,''))
        match_file = @themeSassFiles[theme].hasOwnProperty(import_url)

      if match_file
        import_url = @themeSassFiles[theme][import_url]
      else
        import_url = imp_url
      import_url
    if theme != @baseDir
      url = getAbsImport(url, prev)
    return { file: url }

  _nativeCompile: (source, themeDirs ,callback)=>
    theme = themeDirs.pop()
    self = @
    libsass.render {
      data: source.data
      includePaths: @_getIncludePaths(source.path)
      outputStyle: 'nested'
      sourceComments: !@optimize
      sourceMap: true
      outFile: sysPath.join(self.outPath, theme, 'css')
      importer: (url, prev, done)=>
          result = @_urlImporter(url, prev, theme)
          return { file: result.file }
    }, (error, result) ->
      if error
        callback error.message || util.inspect(error)
      else
        if result.css
          data = result.css.toString()
          writePath = sysPath.join(self.outPath, theme, "css", sysPath.normalize(sysPath.basename(source.path, '.scss')))
          mkdirp sysPath.dirname(writePath), (err)->
            if err
              console.log err.red
            else
              fs.writeFile writePath.concat('.css'), data, (err)->
                if err
                  console.log err.red
                else
                  #Output successful file creation to console.
                  msg = 'Wrote: '.green + theme.toUpperCase().underline + ' ' +
                        sysPath.basename(source.path, '.scss').bold+'.css'.bold +
                        ' -> '.reset + sysPath.join(self.outPath, theme, 'css')
                  console.log(msg)

                  #Create the .map files for each css file if map data exists.
                  if result.map
                    map = result.map.toString()
                    fs.writeFile writePath.concat('.map'), map, (err)->
                      if err
                        console.log(error)

                  #Recursively go through each theme dir and compile until they are all done.
                  #If all done fire callback
                  if themeDirs.length
                    self._nativeCompile(source, themeDirs, callback)
                  else
                    callback null, null


  compile: (data, path, callback) =>
    if !data.trim().length
      return callback(null, '')
    dirs = @_getDirectories @absRootDir
    source =
      data: data
      path: path
    @_nativeCompile source, dirs, callback

    return

module.exports = ThemesCSSCompiler
