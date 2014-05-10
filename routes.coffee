exports.init = (conn, mongoose) ->
  Grid = require 'gridfs-stream'
  Grid.mongo = mongoose.mongo
  GridStore = mongoose.mongo.GridStore
  StreamGridFile = require('./toolbox').StreamGridFile

  model = require('./model').init(mongoose)

  gfs = Grid conn.db
  gfs.exist = GridStore.exist.bind gfs, conn.db
  gfs.list = GridStore.list.bind gfs, conn.db

  @getAllSongs = (req, res) ->
    model.Song.find (err, songs) ->
      res.writeHead 200, 'Content-Type': 'application/json', 'X-Powered-By': 'MarkusL'
      res.end JSON.stringify songs

  @upload = (req, res) ->
    writestream = gfs.createWriteStream filename: "#{req.query.artist}|#{req.query.album}|#{req.query.title}"
    req.pipe writestream
    writestream.on 'close', (file) ->
      newSong = new model.Song
        title: req.query.title
        artist: req.query.artist
        album: req.query.album
        fileId: file._id
      newSong.save (err, song) ->
        res.writeHead 200, 'Content-Type': 'text/html', 'X-Powered-By': 'MarkusL'
        res.end JSON.stringify(song)

  @getSong = (req, res) ->
    model.Song.findById req.params.songId, (err, song) ->
      if !err
        new GridStore(conn.db, song.fileId, null, 'r').open (err, gridFile) ->
          if gridFile
            StreamGridFile req, res, gridFile
          else
            res.send 404, "Not Found"

  @deleteSong = (req, res) ->
    model.Song.findOne _id: req.params.songId, (err, song) ->
      if !err then gfs.remove _id: song.fileId, () ->
        song.remove()
        res.end()

  @goHome =  (req, res) ->
    res.render 'home'

  @login = (req, res) ->
    res.render 'login'
  this
