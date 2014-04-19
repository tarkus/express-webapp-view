should = require 'should'
express = require 'express'
request = require 'request'

webapp_view = require '../lib'

describe 'Express Webapp View', ->

  before (done) ->
    app = express()

    app.use "/templates", webapp_view.connect
      webroot: "#{__dirname}",
      apps: [ 'dummy' ]

    app.get "/", (req, res, next) ->
      res.send templates.dummy.all.src
    app.listen 23456

    done()


  it "should set output webapp's templates", (done) ->
    request 'http://localhost:23456', (error, response, body) ->
      body.should.match /\/dummy-(.*)\.js/
      src = body
      request "http://localhost:23456#{src}", (error, response, body) ->
        body.should.match /Hello/
        body.should.match /Nihil/
        done()
