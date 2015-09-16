sysPath = require('path')
util = require('util')
libsass = require('node-sass')
fs = require('fs')
copy = require('recursive-copy')
colors = require('colors')


anymatch = require('anymatch')

sassRe = /\.[sc][ac]?ss$/

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
    @brunchConfig = @cfg
    @pluginConfig = if (@cfg.plugins and @cfg.plugins.themes and @cfg.plugins.themes.options ) then @cfg.plugins.themes.options else {}
    @pluginConfig.directory = 'themes' if !@pluginConfig.directory
    @pluginConfig.base = 'base' if !@pluginConfig.base
    @pluginConfig.styles = 'sass' if !@pluginConfig.styles

    #Set theme URL's
    @themesDir = sysPath.resolve 'app', @pluginConfig.directory
    @baseDir = sysPath.join @themesDir, @pluginConfig.base

    @_copyStyles @_getThemes(@themesDir)

  _getThemes: (path) =>
    fs.readdirSync(path).filter (file) =>
      stat = fs.statSync(sysPath.join(path, file))
      stat if stat.isDirectory() and file != @pluginConfig.base

  _copyStyles: (themes, overwrite=false) =>
    _themes = themes
    console.log _themes
    theme = _themes.pop()
    from = sysPath.join(@baseDir, @pluginConfig.styles)
    to = sysPath.join(@themesDir, theme, @pluginConfig.styles)

#    checkDir = (filename, dir) =>
#      console.log filename, dir
#      return sysPath.join dir, filename
#      file_to = file.replace(from, to)
#      fs.stat file_to, (err, stat) =>
#        if err
#          return false
#        else if stat
#          return true

    options =
      overwrite: false
      dot: false
      junk: false

    copy from, to, options, (error, results)=>
      if error
        console.log error
      else
        console.log results
      @_copyStyles(_themes) if _themes.length


  _getIncludePaths: (path) =>
    includePaths = [
      @rootPath
      sysPath.dirname(path)
    ]
    if Array.isArray(@includePaths)
      includePaths = includePaths.concat(@includePaths)
    includePaths

  _nativeCompile: (source, callback)=>
    libsass.render {
      data: source.data
      includePaths: @_getIncludePaths(source.path)
      outputStyle: (@brunchConfig.optimize) ? 'compressed':'nested'
      indentedSyntax: (sysPath.extname(source.path) == '.sass')
      sourceComments: !@optimize
      sourceMap: true
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