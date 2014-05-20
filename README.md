mirror
======

```coffee

  # Create a mirror
  mirror = new Mirror 'testing'

  # Do stuff when it's ready
  mirror.startup -> # Runs in main app AND mirror on EVERY mirror restart

    if mirror.isMirror # Runs inside the mirror after Meteor.startup
      console.log "I'm inside the mirror"

      # Listen for messages from the main app
      mirror.subscribe (msg) -> # Callback is safe for normal Meteor calls
        console.log "Mirror recieved a message from the main app: #{msg}"

        # Send a message back to the main app
        mirror.publish 'pong' if msg is 'ping'

    else # Runs in the main app when the mirror has run all its startup callbacks
      console.log "I'm inside the main app"

      # Listen for messages from the mirror
      mirror.subscribe (msg) ->
        console.log "Main app recieved a message from the mirror: #{msg}"

      # Send a message to the mirror
      mirror.publish 'ping'

  # Start the mirror from the main app
  unless mirror.isMirror

    mirror.start (err) -> # Runs ONCE after main app mirror.startup (or error)
      return console.log 'There was an error starting the mirror' if err?
      console.log "Mirror started successfully"

    # Kill the mirror after a little while
    setTimeout ->
      console.log "Stopping the mirror"
      mirror.stop()
    , 10000
```

### Example [Meteor.settings](http://docs.meteor.com/#meteor_settings) configuration

```json
{
  "mirror": {
    "debug": true,
    "current":null,
    "stdout": true,
    "stderr": true,
 }
}
```
