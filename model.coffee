exports.init = (mongoose) ->
  Schema = mongoose.Schema
  @Song = mongoose.model 'Song',
      title: String
      artist: String
      album: String
      fileId: Schema.ObjectId
  this

