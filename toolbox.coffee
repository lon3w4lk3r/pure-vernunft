exports.StreamGridFile = (req, res, GridFile) ->
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