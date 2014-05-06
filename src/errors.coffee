
Mirror.Error = {}

class Mirror.Error.NameRequired extends Error
  constructor: (@message) ->
    @message ?= 'Mirror requires a name'

class Mirror.Error.AlreadyCreated extends Error
  constructor: (name) ->
    @message = "Mirror with name '#{name}' already created"

class Mirror.Error.Inception extends Error
  constructor: ->
    @message = 'Cannot start mirror from within itself'

class Mirror.Error.OnlyMirror extends Error
  constructor: (method) ->
    @message = "Can only call #{method} from within a mirror"

class Mirror.Error.ExceptMirror extends Error
  constructor: (method) ->
    @message = "Cannot call #{method} from within a mirror"

class Mirror.Error.OnlyCurrentMirror extends Error
  constructor: (method) ->
    @message = "Can only call #{method} from within current mirror"

class Mirror.Error.ExceptCurrentMirror extends Error
  constructor: (method) ->
    @message = "Cannot call #{method} from within current mirror"

class Mirror.Error.TimedOut extends Error
  constructor: (name) ->
    @message = "Mirror named '#{name}' timed out"

class Mirror.Error.UnknownExit extends Error
  constructor: (name) ->
    @message = "Mirror app #{name} exited weird"
