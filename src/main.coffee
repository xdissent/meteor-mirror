
# Only an actual mirror needs this
if Mirror.isMirror?

  # Always exit with parent process
  process.stdin.resume()
  process.stdin.on 'end', -> process.exit()

  # Keep track of listening state
  WebApp.onListening -> Mirror._listening = true
