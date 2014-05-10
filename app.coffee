mongoose = require 'mongoose'
Schema = mongoose.Schema
Grid = require 'gridfs-stream'
Grid.mongo = mongoose.mongo
ObjectID = mongoose.mongo.ObjectID
GridStore = mongoose.mongo.GridStore
express = require 'express'
path = require 'path'

# process.env.NODE_ENV = 'production'

mongoose.connect 'mongodb://localhost/music'
conn = mongoose.connection

conn.once 'open', () ->
  gfs = Grid conn.db
  gfs.exist = GridStore.exist.bind gfs, conn.db
  gfs.list = GridStore.list.bind gfs, conn.db

  Song = mongoose.model 'Song',
    title: String
    artist: String
    album: String
    fileId: Schema.ObjectId

  app = express()
  app.use require('connect-assets')()

  app.set 'views', path.join(__dirname, 'views')
  app.set 'view engine', 'jade', doctype: '5'

  app.post '/upload', (req, res) ->
    writestream = gfs.createWriteStream filename: "#{req.query.artist}|#{req.query.album}|#{req.query.title}"
    req.pipe writestream
    writestream.on 'close', (file) ->
      newSong = new Song
        title: req.query.title
        artist: req.query.artist
        album: req.query.album
        fileId: file._id
      newSong.save (err, song) ->
        res.writeHead 200, 'Content-Type': 'text/html', 'X-Powered-By': 'MarkusL'
        res.end JSON.stringify(song)

  app.get '/stream/:songId', (req, res) ->
    Song.findById req.params.songId, (err, song) ->
      if !err
        new GridStore(conn.db, song.fileId, null, 'r').open (err, gridFile) ->
          if gridFile
            StreamGridFile req, res, gridFile
          else
            res.send 404, "Not Found"

  app.delete '/song/:songId', (req, res) ->
    Song.findOne _id: req.params.songId, (err, song) ->
      if !err then gfs.remove _id: song.fileId, () ->
        song.remove()
        res.end()

  app.get '/downloads', (req, res) ->
    Song.find (err, songs) ->
      res.writeHead 200, 'Content-Type': 'application/json', 'X-Powered-By': 'MarkusL'
      res.end JSON.stringify songs

  app.get '/home', (req, res) ->
    res.render 'home'

  PORT = 3012;
  app.listen PORT, () ->
    console.log "Listening on " + PORT


StreamGridFile = (req, res, GridFile) ->
  if req.headers['range']
    parts = req.headers['range'].replace(/bytes=/, "").split "-"
    partialstart = parts[0]
    partialend = parts[1]

    start = parseInt partialstart, 10
    end = partialend && partialend != "" && parseInt(partialend, 10) ||  GridFile.length - 1
    chunksize = end-start+1

    res.writeHead 206,
      'Content-Range': "bytes #{start}-#{end}/#{GridFile.length}"
      'Accept-Ranges': 'bytes'
      'Content-Length': chunksize
      'Content-Type': GridFile.contentType

    current = start

    GridFile.seek start, () ->
      stream = GridFile.stream true
      stream.on 'data', (buff) ->
        current += buff.length
        if current >= end
          GridFile.close()
          res.end()
        else
          res.write buff
  else
    res.header 'Content-Type', GridFile.contentType
    res.header 'Content-Length', GridFile.length
    stream = GridFile.stream true
    stream.pipe res