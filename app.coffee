mongoose = require 'mongoose'
express = require 'express'
path = require 'path'

# process.env.NODE_ENV = 'production'

mongoose.connect 'mongodb://localhost/music'
conn = mongoose.connection

conn.once 'open', () ->
  routes = require("./routes.js").init conn, mongoose

  app = express()
  app.use require('connect-assets')()

  app.set 'views', path.join(__dirname, 'views')
  app.set 'view engine', 'jade', doctype: '5'

  app.post '/upload', routes.upload
  app.get '/stream/:songId', routes.getSong
  app.delete '/song/:songId', routes.deleteSong
  app.get '/downloads', routes.getAllSongs
  app.get '/home', routes.goHome

  PORT = 3012;
  app.listen PORT, () ->
    console.log "Listening on " + PORT

