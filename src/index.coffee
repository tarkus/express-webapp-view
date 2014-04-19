fs        = require 'fs'
path      = require 'path'
jade      = require 'jade'
crypto    = require 'crypto'
UglifyJS  = require 'uglify-js'

output = {}
maps = {}

generate = (name, opts={}) ->
  templates = {}
  parent_dir = path.dirname module.parent.filename
  if opts.webroot
    if opts.webroot.indexOf("/") isnt 0

      dir = "#{parent_dir}/#{opts.webroot}/#{name}/views"
    else
      dir = "#{opts.webroot}/#{name}/views"
  else
    dir = "#{parent_dir}/public/javascripts/#{name}/views"

  for file in fs.readdirSync(dir)
    id = file.split(".")[0]
    content = fs.readFileSync(dir + "/" + file).toString()

    unless opts.i18n
      templates['all'] ?= []
      func = jade.compileClient content
      templates['all'].push "templates['#{id}'] = #{func.toString()};"
      continue

    for lang, locale of opts.i18n.locales()
      templates[lang] = [] unless templates[lang]?
      translate = opts.i18n.chose lang
      translated = content.replace /^\s*\=\s*[\!]?t\(['|"]([^'|"]+)['|"]\)/g, (match, str) ->
        "| " + translate str
      translated = translated.replace /\=\s*[\!]?t\(['|"]([^'|"]+)['|"]\)/g, (match, str) ->
        translate str
      func = jade.compileClient translated
      templates[lang].push "templates['#{id}'] = #{func.toString()};"

  sources = {}
  for lang, partials of templates
    script = """ 
      if (typeof templates == "undefined") templates = {};
      #{partials.join("\n")}
    """
    minified = UglifyJS.minify script, { fromString: true }
    content = minified.code
    hash = crypto.createHash 'md5'
    hash.update content, "utf-8"
    revision = hash.digest("hex")

    src = "/#{[name, revision].join("-")}.js"

    sources[lang] =
      content: content
      revision: revision
      src: "#{opts.prefix or '/templates'}#{src}"

    maps[src] = content

  sources

exports.connect = (options) ->
  options.apps = [options.apps] if typeof options.apps is 'string'
  output[name] = generate name, options for name in options.apps
  options.context ?= global
  options.context.templates = output

  (req, res, next) ->
    return res.send 404 unless maps[req.path]?
    res.set "Content-Type", "application/javascript"
    return res.send maps[req.path]
