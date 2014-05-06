
path = Npm.require 'path'
child_process = Npm.require 'child_process'
freeport = Npm.require 'freeport'

debug = -> console.log 'Mirror -', arguments... if Mirror.settings.debug

settings =
  debug: Meteor.settings.mirror?.debug
  current: Meteor.settings.mirror?.current


class Mirror

  @SECRET = '__mirror_mirror__'

  @settings: settings
  @current: settings.current?.name
  @isMirror: settings.current?

  @_mirrors: {}
  @_listening: false

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
    return @_child.send msg unless @isMirror
    process.send mirror: @name, message: msg

  subscribe: (callback) ->
    @_subscriptions.push [Meteor.bindEnvironment(callback), callback]

  unsubscribe: (callback) ->
    @_subscriptions = _.reject @_subscriptions, (subscription) ->
      subscription[1] is callback

  start: (callback) ->
    return callback new Mirror.Error.ExceptCurrentMirror if @isMirror
    return callback null if @_child?
    callback = Meteor.bindEnvironment callback
    return @_start_callbacks.push callback if @_starting
    @_starting = true
    @_spawn (err) => @_runStartCallbacks err, callback

  stop: ->
    throw new Mirror.Error.ExceptCurrentMirror if @isMirror
    @_child.kill() if @_child?

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
    return @_startMirror() if Mirror._listening
    WebApp.onListening => @_startMirror()

  _startMirror: ->
    callback() for callback in @_startup_callbacks
    @publish Mirror.SECRET
    process.on 'message', (msg) =>
      subscription[0] msg for subscription in @_subscriptions

  _initParent: ->
    @port ?= @_randomPort()
    @_starting = false
    @_start_callbacks = []
    @_child = null
    @_path = path.join process.env.PWD, '.meteor', 'local', 'build', 'main.js'
    meteor_settings = _.extend {}, @settings, mirror:
      debug: Mirror.settings.debug
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
    @_child = null if err?
    @_starting = false
    cb err for cb in callbacks

  _isMyMessage: (msg) -> msg?.mirror is @name

  _isSecretMessage: (msg) -> msg?.message is Mirror.SECRET and @_isMyMessage msg

  _spawn: (callback) ->
    timed_out = false
    kill_timeout = setTimeout =>
      @debug 'Killing child after timeout'
      timed_out = true
      @stop()
    , 30000

    cb = _.once ->
      clearTimeout kill_timeout
      callback arguments...

    @_child = child_process.fork @_path, @_options

    @_child.once 'close', =>
      @_starting = false
      @_child = null
      @debug 'Mirror was closed', timed_out, arguments...
      return cb new Mirror.Error.TimedOut @name if timed_out
      cb new Mirror.Error.UnknownExit @name

    @_child.stdout.on 'data', (chunk) =>
      console.log "Mirror - (#{@name})",
        chunk.toString().replace /\s$/, ''

    @_child.stderr.on 'data', (chunk) =>
      console.log "Mirror - (#{@name}) (STDERR)",
        chunk.toString().replace /\s$/, ''

    subscriptions = (msg) =>
      @debug 'Mirror parent got message', msg
      return unless @_isMyMessage msg and not @_isSecretMessage msg
      subscription[0] msg.message for subscription in @_subscriptions

    secret_msg = (msg) =>
      @debug 'Mirror parent got message', msg
      return unless @_isSecretMessage msg
      @debug 'Mirror parent got secret message', msg
      @_child.removeListener 'message', secret_msg
      @_child.on 'message', subscriptions
      cb null

    @_child.on 'message', secret_msg
