mongoose = require 'mongoose'
express = require 'express'
path = require 'path'
passport = require 'passport'
GoogleStrategy = require('passport-google').Strategy
ensureAuthenticated = require('./toolbox').ensureAuthenticated

passport.serializeUser (user, done) ->
  done null, user

passport.deserializeUser (obj, done) ->
  done null, obj

passport.use new GoogleStrategy
  returnURL: 'http://localhost:3012/auth/google/return'
  realm: 'http://localhost:3012'
  ,
  (identifier, profile, done) ->
    profile.identifier = identifier
    done null, profile

# process.env.NODE_ENV = 'production'

mongoose.connect 'mongodb://localhost/pure-vernunft'
conn = mongoose.connection

conn.once 'open', () ->
  routes = require("./routes.js").init conn, mongoose

  app = express()
  app.use require('connect-assets')()
  app.use require('cookie-parser')()
  app.use require('body-parser')()
  app.use require('method-override')()
  app.use require('express-session') secret: "Unglaublich tolles, sehr geheimes Geheimniss"
  app.use passport.initialize()
  app.use passport.session()
  app.use express.static "#{__dirname}/public"
  app.set 'views', "#{__dirname}/views"
  app.set 'view engine', 'jade', doctype: 'html'

  app.post '/upload', ensureAuthenticated, routes.upload
  app.get '/stream/:songId', ensureAuthenticated, routes.getSong
  app.delete '/song/:songId', ensureAuthenticated, routes.deleteSong
  app.get '/downloads', ensureAuthenticated, routes.getAllSongs
  app.get '/home', ensureAuthenticated, routes.goHome
  app.get '/', routes.login
  app.get '/auth/google',
    passport.authenticate( 'google',
      failureRedirect: '/'),
    (req, res) -> res.redirect '/home'
  app.get '/auth/google/return',
    passport.authenticate('google',
      failureRedirect: '/'),
    (req, res) -> res.redirect '/home'
  app.get '/logout', (req, res) ->
    req.logout()
    res.redirect '/'

  PORT = 3012;
  app.listen PORT, () ->
    console.log "Listening on " + PORT