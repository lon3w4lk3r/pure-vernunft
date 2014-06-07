pure-vernunft
=============

Very basic music server.

A user can upload his songs and play them back in the browser.

About the architecture:
- Streams uploaded songs directly to and from the database while providing, resulting in a low memory footprint
- extracts mp3 metadata
- Provides seek functionality
- Uses javascript preprocessor (client and server), serverside and clientside templating for modularisition and compactness
- demonstrates the combination of a range of interesting technologies
 * CoffeScript
 * connect-assets for client-side CoffeeScript
 * AngularJS and Jade for templating
 * gridfs-stream to stream binary files
 * mongodb with schemas, using mongoose
 * id3 for reading mp3 metadata
