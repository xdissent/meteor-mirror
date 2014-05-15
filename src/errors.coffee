
class Mirror.Error extends Error
  constructor: (@message) ->
    @message ?= 'Mirror error'

class Mirror.Error.NameRequired extends Mirror.Error
  constructor: (@message) ->
    @message ?= 'Mirror requires a name'

class Mirror.Error.AlreadyCreated extends Mirror.Error
  constructor: (name) ->
    @message = "Mirror with name '#{name}' already created"

class Mirror.Error.Inception extends Mirror.Error
  constructor: ->
    @message = 'Cannot start mirror from within itself'

class Mirror.Error.OnlyMirror extends Mirror.Error
  constructor: (method) ->
    @message = "Can only call #{method} from within a mirror"

class Mirror.Error.ExceptMirror extends Mirror.Error
  constructor: (method) ->
    @message = "Cannot call #{method} from within a mirror"

class Mirror.Error.OnlyCurrentMirror extends Mirror.Error
  constructor: (method) ->
    @message = "Can only call #{method} from within current mirror"

class Mirror.Error.ExceptCurrentMirror extends Mirror.Error
  constructor: (method) ->
    @message = "Cannot call #{method} from within current mirror"

class Mirror.Error.TimedOut extends Mirror.Error
  constructor: (name) ->
    @message = "Mirror named '#{name}' timed out"

class Mirror.Error.UnknownExit extends Mirror.Error
  constructor: (name) ->
    @message = "Mirror app #{name} exited weird"
