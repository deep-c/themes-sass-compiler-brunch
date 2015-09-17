sysPath = require('path')
util = require('util')
libsass = require('node-sass')
fs = require('fs')
anymatch = require('anymatch')
sassRe = /\.s[ac]?ss$/

extend = (object, source) ->
  for key of source
    object[key] = source[key]
  object

class ThemesCompiler
  brunchPlugin: yes
  type: 'stylesheet'
  pattern: sassRe

  constructor: (@cfg) ->
    #Set config options
    @config = @cfg
    @theme = @config.env.toString()
    @pluginConfig = (@cfg.plugins && @cfg.plugins.themes ) || {};
    if @pluginConfig.options
      @includePaths = @pluginConfig.options.includePaths if @pluginConfig.options.includePaths
      @themes = @pluginConfig.options.directory
      @theme =  @pluginConfig.options.base if !@theme
      @styles = @pluginConfig.options.styles
    @stylesFiles = @_getFilesInDir(sysPath.join(sysPath.resolve('app'), @themes, @theme, @styles), sassRe)

  _getFilesInDir: (dir, filter) ->
    results = {}
    if !fs.existsSync(dir)
      return
    files = fs.readdirSync(dir)
    i = 0
    while i < files.length
      filename = sysPath.join(dir, files[i])
      stat = fs.lstatSync(filename)
      if stat.isDirectory()
        results = extend(results, @_getFilesInDir(filename, filter))
      else if anymatch(filter, filename)
        importPath = filename.replace('_', '').replace(sassRe,'')
        results[importPath] = filename
      i++
    results

  _getIncludePaths: (path) =>
    includePaths = [
      @rootPath
      sysPath.dirname(path)
    ]
    if Array.isArray(@includePaths)
      includePaths = includePaths.concat(@includePaths)
    includePaths

  _urlImporter: (url, prev) =>
    #Convert import urls to absolute paths and match against theme for substitution
    sassDir = sysPath.join(sysPath.resolve('app'), @themes, @theme, @styles)
    baseDir = sysPath.join('app', @themes, @pluginConfig.options.base, @styles)

    getAbsImport = (imp_url, prev_url) =>
      if prev_url != "stdin"
        import_url = sysPath.dirname(sysPath.join(sassDir, prev_url.replace(baseDir, '')))
        import_url = sysPath.join(import_url,imp_url)
      else
        import_url = sysPath.join(sassDir, imp_url.replace(baseDir, ''))
      match_file = @stylesFiles.hasOwnProperty(import_url)
      import_url = if match_file then @stylesFiles[import_url] else imp_url
      import_url

    if @theme != @pluginConfig.options.base
      url = getAbsImport(url, prev)

    return { file: url }

  _nativeCompile: (source, callback)=>
    libsass.render {
      data: source.data
      includePaths: @_getIncludePaths(source.path)
      outputStyle: (@config.optimize) ? 'compressed':'nested'
      indentedSyntax: (sysPath.extname(source.path) == '.sass')
      sourceComments: !@optimize
      importer: (url, prev, done)=>
          result = @_urlImporter(url, prev)
          return { file: result.file }
    }, (error, result) =>
      if error
        callback error.message || util.inspect(error)
      else
        if result.css
          data = result.css.toString()
          callback null, data

  compile: (data, path, callback) =>
    return callback(null, '') if !data.trim().length
    source =
      data: data
      path: path
    @_nativeCompile source, callback

    return


module.exports = ThemesCompiler