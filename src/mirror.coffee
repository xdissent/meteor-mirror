
path = Npm.require 'path'
child_process = Npm.require 'child_process'
freeport = Npm.require 'freeport'

debug = -> console.log 'Mirror -', arguments... if Mirror.settings.debug


class Mirror

  # Secret message to indicate successful mirror startup
  @SECRET = '__mirror_mirror__'

  # Current mirror name if any
  @current: settings.current?.name

  # Boolean indicating whether the current context is a mirror
  @isMirror: settings.current?

  # Global settings, overridden per mirror instance
  @settings:
    debug: Meteor.settings.mirror?.debug
    current: Meteor.settings.mirror?.current
    stdout: Meteor.settings.mirror?.stdout ? true
    stderr: Meteor.settings.mirror?.stderr ? true

  @_mirrors: {}

  @_init: ->
    # Only an actual mirror needs this
    return unless Mirror.isMirror?
    # Always exit with parent process
    process.stdin.resume()
    process.stdin.on 'end', -> process.exit()

  constructor: (@name, @port, @settings = {}) ->
    throw new Mirror.Error.NameRequired unless @name?
    throw new Mirror.Error.AlreadyCreated @name if Mirror._mirrors[@name]?
    @debug 'Creating mirror'
    [@settings, @port] = [@port, null] if typeof @port is 'object'
    @_initCommon()
    return @_initMirror() if @isMirror
    @_initParent()

  debug: ->
    return debug "(#{@name})", arguments... unless @isMirror
    console.log arguments... if Mirror.settings.debug

  startup: (callback) ->
    @debug 'Adding startup callback'
    @_startup_callbacks.push Meteor.bindEnvironment callback

  publish: (msg) ->
    @debug 'Publishing msg', msg
    return @child.send msg unless @isMirror
    process.send mirror: @name, message: msg

  subscribe: (callback) ->
    @_subscriptions.push [Meteor.bindEnvironment(callback), callback]

  unsubscribe: (callback) ->
    @_subscriptions = _.reject @_subscriptions, (subscription) ->
      subscription[1] is callback

  start: (callback) ->
    return callback new Mirror.Error.ExceptCurrentMirror if @isMirror
    return callback() if @child?
    callback = Meteor.bindEnvironment callback
    return @_start_callbacks.push callback if @_starting
    @_starting = true
    @_spawn (err) => @_runStartCallbacks err, callback

  stop: ->
    throw new Mirror.Error.ExceptCurrentMirror if @isMirror
    @child.kill() if @child?

  _initCommon: ->
    Mirror._mirrors[@name] = this
    @_subscriptions = []
    @_startup_callbacks = []
    @isMirror = Mirror.current is @name

  _initMirror: ->
    @port = Mirror.settings.current.port
    @settings = Mirror.settings.current.settings
    @root_url = "http://localhost:#{@port}/"
    @mongo_url = "mongodb://127.0.0.1:3001/#{@name}"
    # Run startup callbacks at the appropriate time
    startup = Meteor.bindEnvironment => @_startMirror()
    if Package.webapp # Run immediately if webapp pkg included and listening
      return startup() if Package.webapp.WebApp.httpServer?._handle?
      return Package.webapp.WebApp.onListening startup # Run when listening
    return startup() if Package.mirror? # Run immediately if already loaded pkg
    Meteor.startup startup # Run upon meteor startup

  _startMirror: ->
    callback() for callback in @_startup_callbacks
    @publish Mirror.SECRET
    process.on 'message', (msg) =>
      subscription[0] msg for subscription in @_subscriptions

  _initParent: ->
    @port ?= @_randomPort()
    @root_url = "http://localhost:#{@port}/"
    @_starting = false
    @_start_callbacks = []
    @child = null
    @_path = path.join process.env.PWD, '.meteor', 'local', 'build', 'main.js'
    meteor_settings = _.extend {}, Meteor.settings, @settings, mirror:
      current:
        name: @name
        port: @port
        settings: @settings

    @_options =
      silent: true
      cwd: process.env.PWD
      env: _.extend {}, process.env,
        PORT: @port
        ROOT_URL: "http://localhost:#{@port}/"
        MONGO_URL: "mongodb://127.0.0.1:3001/#{@name}"
        METEOR_SETTINGS: JSON.stringify meteor_settings

  _randomPort: -> Meteor._wrapAsync(freeport)()

  _runStartCallbacks: (err, callback) ->
    callbacks = if err? then [] else @_startup_callbacks
    callbacks = callbacks.concat @_start_callbacks, callback
    @_start_callbacks = []
    @child = null if err?
    @_starting = false
    cb err for cb in callbacks

  _isMyMessage: (msg) -> msg?.mirror is @name

  _isSecretMessage: (msg) -> msg?.message is Mirror.SECRET and @_isMyMessage msg

  _spawn: (callback) ->
    timed_out = false
    timeout = setTimeout =>
      @debug 'Killing child after timeout'
      timed_out = true
      child.kill()
    , 30000

    cb = _.once ->
      clearTimeout timeout
      callback arguments...

    child = child_process.fork @_path, @_options

    child.once 'close', =>
      @_starting = false
      @child = null
      @debug 'Mirror was closed', timed_out, arguments...
      return cb new Mirror.Error.TimedOut @name if timed_out
      cb new Mirror.Error.UnknownExit @name

    child.stdout.pipe process.stdout if Mirror.settings.stdout
    child.stderr.pipe process.stderr if Mirror.settings.stderr

    subscriptions = (msg) =>
      @debug 'Mirror parent got message', msg
      return unless @_isMyMessage(msg) and not @_isSecretMessage msg
      subscription[0] msg.message for subscription in @_subscriptions

    secret_msg = (msg) =>
      @debug 'Mirror parent got message', msg
      return unless @_isSecretMessage msg
      @debug 'Mirror parent got secret message', msg
      child.removeListener 'message', secret_msg
      child.on 'message', subscriptions
      @child = child
      cb null

    child.on 'message', secret_msg
