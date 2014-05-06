
Mirror.Error =
  NameRequired: class NameRequiredError extends Error
    constructor: (@message) ->
      @message ?= 'Mirror requires a name'

  AlreadyCreated: class AlreadyCreatedError extends Error
    constructor: (name) ->
      @message = "Mirror with name '#{name}' already created"

  Inception: class InceptionError extends Error
    constructor: ->
      @message = 'Cannot start mirror from within itself'

  OnlyMirror: class OnlyMirrorError extends Error
    constructor: (method) ->
      @message = "Can only call #{method} from within a mirror"

  ExceptMirror: class ExceptMirrorError extends Error
    constructor: (method) ->
      @message = "Cannot call #{method} from within a mirror"

  OnlyCurrentMirror: class OnlyCurrentMirrorError extends Error
    constructor: (method) ->
      @message = "Can only call #{method} from within current mirror"

  ExceptCurrentMirror: class ExceptCurrentMirrorError extends Error
    constructor: (method) ->
      @message = "Cannot call #{method} from within current mirror"

  TimedOut: class TimedOutError extends Error
    constructor: (name) ->
      @message = "Mirror named '#{name}' timed out"

  UnknownExit: class UnknownExitError extends Error
    constructor: (name) ->
      @message = "Mirror app #{name} exited weird"
