vm = require \vm
Script = vm.Script

{Board} = require './board'

exports.BotExecutor = class BotExecutor

  @mandatory-args = []
  @mandatory = (...args) ->
    @mandatory-args .= concat args

  @optional-args = []
  @optional = (...args) ->
    @optional-args .= concat args

  @mandatory 'board', 'botId', 'code'
  @optional 'logPath'

  (options) ->
    @_parse-options options
    @_create-evaluation-context()
    @_create-scripts()
    @_validate()

  new-game: ->
    @_run @_new-game

  make-move: ->
    @_run @_make-move

  _validate: ->
    @_validate-bot-id()
    @_validate-make-move-present()

  _validate-bot-id: ->
    unless @board.has-bot @bot-id
      throw new Error "Invalid botId '#{@bot-id}'"

  _validate-make-move-present: ->
    if ("typeof make_move" |> @_create-script |> @_run) isnt 'function'
      throw new Error "Invalid argument. code doesn't define make_move() function"

  _parse-options: (options) ->
    for field in @@mandatory-args
      if options[field]?
        @[field] = options[field]
      else
        throw new Error "Missing mandatory arg #field"

    for field in @@optional-args
      if options[field]?
        @[field] = options[field]

  _create-evaluation-context: ->
    @code |> @_create-script |> @_run

  _create-scripts: ->
    @_make-move = @_create-script('make_move();')
    @_new-game = @_create-script("if (typeof new_game === 'function') new_game();")

  _run: (script) ->
      script.run-in-context @_get-context()

  _get-context: ->
    @_context ?= vm.create-context(
      WIDTH: @board.get-width()
      HEIGHT: @board.get-height()
      NORTH: Board.NORTH
      EAST: Board.EAST
      SOUTH: Board.SOUTH
      WEST: Board.WEST
      TAKE: Board.TAKE
      PASS: Board.PASS
    )

  _create-script: (code) ->
    new Script code, @_get-filename()

  _get-filename: ->
    @_filename ?= "#{@bot-id}.bot.js"
