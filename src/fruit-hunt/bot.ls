vm = require \vm
Script = vm.Script

exports.Bot = class Bot
  ({@id, @code, @log-path}) ->
    @_validate-mandatory-field 'id'
    @_validate-mandatory-field 'code'
    @_create-definitions-script()
    @_static-scripts = {}

  get-log-path: -> @log-path

  set-log-path: (@log-path) ->

  _validate-mandatory-field: (field) ->
    unless @[field]?
      throw new Error "Missing mandatory arg #field"

  _create-definitions-script: ->
    try
      @_definitions = @_new-script @code
    catch err
      @_error-in-code err

  _new-script: (code) ->
    new Script code, @_get-filename()

  _get-filename: ->
    @_filename ?= "#{@id}.bot.js"

  _error-in-code: (err) ->
    msg = "Invalid code for bot #{@id}: #{@code} raised the following error '#err'"
    throw new Error msg

  get-context: -> @_context

  # sandbox is an object containing definitions for the globals that will be available in the new context
  set-new-context: (sandbox) ->
    @_context = vm.create-context sandbox
    @_definitions.run-in-context @_context

  reset-context: ->
    @_context = null

  @static-script-strings =
    make_move: 'make_move();'
    new_game: "if (typeof new_game !== 'undefined') new_game();"

  make-move: ~>
    @_execute-static-script 'make_move'

  new-game: ~>
    @_execute-static-script 'new_game'

  _execute-static-script: (script-name) ->
    if @get-context()?
      @_run-script @_get-static-script script-name
    else
      throw new Error "No execution context set for bot #{@id}. Please use .setNewContext(context) to set the execution context before calling this method."

  _run-script: (script) ->
    try
      script.run-in-context @get-context()
    catch err
      throw new Error "#{@id} threw an error: '#{err.to-string()}'"

  _get-static-script: (script-name) ->
    @_static-scripts[script-name] ?= @_new-script @@static-script-strings[script-name]
