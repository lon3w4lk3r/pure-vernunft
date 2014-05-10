postSong = (item, $scope) ->
  file = item.file
  url = file.urn || file.name

  ID3.loadTags url, () ->
      postMP3 url, file, $scope
    ,
      tags: ["title","artist","album"]
      dataReader: FileAPIReader file
  this

postMP3 = (url, file, $scope) ->
  tags = ID3.getAllTags url
  title = encodeURIComponent tags.title || file.name
  artist = encodeURIComponent tags.artist || ""
  album = encodeURIComponent tags.album || ""

  data = new FormData()
  data.append 'file', file
  data.append 'title2', title

  $.ajax
    url: "upload?title=#{title}&artist=#{artist}&album=#{album}"
    type: 'POST'
    data: data
    cache: false
    dataType: 'json'
    processData: false
    contentType: false
    success: (data) ->
      if data.error
        console.log  data.error
      else
        $scope.$apply () ->
          $scope.vm.songs.push new SongVM(data)
  ,
    error: (jqXHR, textStatus) ->
      console.log 'ERRORS: ' + textStatus

app = angular.module "music-manager", ["angularFileUpload"]

app.controller "MusicCtrl", ($scope, $http, $q, $fileUploader) ->
  $scope.vm = new MusicManagerVM $scope, $http, $q

  uploader = $fileUploader.create()
  uploader.bind "afteraddingfile", (event, item) ->
    postSong item, $scope

SongVM = (song) ->
  @_id = song._id
  @title = song.title
  @artist = song.artist
  @album = song.album
  @fileId = song.fileId
  this

MusicManagerVM = (scope, http, q) ->
  @songs = new Array()
  @scope = scope
  @q = q
  @http = http

  @selectedSong = null
  @message = ""

  @playSong = (idx) =>
    @selectedSong = @songs[idx]
    player = $ '#musicPlayer'
    player.attr 'src', "/stream/#{@selectedSong._id}"
    player[0].play()
    this

  @loadSongs = () =>
    http.get('/downloads').success (data) =>
      @songs = data.map (song) ->
        new SongVM song

  @deleteSong = (idx) =>
    http.delete("/song/#{@songs[idx]._id}").success (data) =>
      if !data.err then @songs.splice idx, 1
    this

  @loadSongs()
  this