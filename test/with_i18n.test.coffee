should = require 'should'
express = require 'express'
request = require 'request'

i18n = require 'express-i18n'
webapp_view = require '../lib'

describe 'Express Webapp View with i18n helper', ->

  before (done) ->
    app = express()

    app.use i18n.connect
      locales:
        en: require "#{__dirname}/locales/en"
        cn: require "#{__dirname}/locales/cn"

    app.use "/templates", webapp_view.connect
      webroot: "#{__dirname}",
      apps: [ 'dummy' ]
      i18n: i18n

    app.get "/", (req, res, next) ->
      res.send templates.dummy.en.src

    app.get "/cn", (req, res, next) ->
      res.send templates.dummy.cn.src
    app.listen 33333

    done()


  en_src = null
  cn_src = null

  it "should output webapp's templates with en locales", (done) ->
    request 'http://localhost:33333', (error, response, body) ->
      body.should.match /\/dummy-(.*)\.js/
      en_src = body

      request "http://localhost:33333#{en_src}", (error, response, body) ->
        body.should.match /Test/
        done()

  it "should output webapp's templates with cn locales", (done) ->
    request 'http://localhost:33333/cn', (error, response, body) ->
      body.should.match /\/dummy-(.*)\.js/
      cn_src = body

      request "http://localhost:33333#{cn_src}", (error, response, body) ->
        body.should.match /测试/
        done()
