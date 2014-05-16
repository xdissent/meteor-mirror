path = Npm.require 'path'

foo = new Mirror 'foo'
bar = new Mirror 'bar'
baz = new Mirror 'baz', # Runs as a child of foo mirror with custom main
  main: path.join process.env.PWD, 'private', 'baz-main.js'

start = (mirror, callback) ->
  console.log "Starting #{mirror.name} mirror"
  mirror.start ->
    console.log "Mirror #{mirror.name} started at #{mirror.root_url}"
    callback() if callback?

if Mirror.isMirror
  console.log "Inside #{Mirror.current} mirror"
  start baz if foo.isMirror # We're inside the foo mirror, so start baz
else
  console.log 'Inside main app'
  start foo, -> start bar # Start foo mirror then bar mirror from main app
