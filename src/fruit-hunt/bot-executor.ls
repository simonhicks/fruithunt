vm = require \vm
fs = require \fs
path = require \path
Script = vm.Script

{Board} = require './board'

exports.BotExecutor = class BotExecutor

  @mandatory-args = <[board botId code]>
  @optional-args = <[logPath]>

  (options) ->
    @_parse-options options
    @_create-evaluation-context()
    @_create-scripts()
    @_validate()
    @_prepare-log-path()

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

  _prepare-log-path: ->
    p = path.dirname @log-path
    unless fs.exists-sync p
      fs.mkdir-sync p

  _parse-options: (options) ->
    for field in @@mandatory-args
      if options[field]?
        @[field] = options[field]
      else
        throw new Error "Missing mandatory arg #field"

    for field in @@optional-args
      if options[field]?
        @[field] = options[field]

  _get-opponent-id: ->
    @_opponent ?= @board.get-opponent @bot-id

  _create-evaluation-context: ->
    @code |> @_create-script |> @_run

  _create-scripts: ->
    @_make-move = @_create-script('make_move();')
    @_new-game = @_create-script("if (typeof new_game === 'function') new_game();")

  _run: (script) ->
    try
      script.run-in-context @_get-context()
    catch err
      @_code-error err

  _code-error: (err) ->
    msg = "Invalid code for bot #{@bot-id}: #{@code} raised the following error '#err'"
    throw new Error msg

  _get-context: ->
    @_context ?= vm.create-context(
      # Constants
      WIDTH: @board.get-width()
      HEIGHT: @board.get-height()
      NORTH: Board.NORTH
      EAST: Board.EAST
      SOUTH: Board.SOUTH
      WEST: Board.WEST
      TAKE: Board.TAKE
      PASS: Board.PASS
      # Functions
      get_board: @board.get-board
      get_my_x: ~>
        @board.get-position(@bot-id).x
      get_my_y: ~>
        @board.get-position(@bot-id).y
      get_opponent_x: ~>
        @board.get-position(@_get-opponent-id()).x
      get_opponent_y: ~>
        @board.get-position(@_get-opponent-id()).y
      has_item: (field) ->
        field > 0
      get_number_of_item_types: ~>
        @board.get-types().length
      get_my_item_count: (type) ~>
        @board.get-score @bot-id, type
      get_opponent_item_count: (type) ~>
        @board.get-score @_get-opponent-id(), type
      get_total_item_count: (type) ~>
        @board.get-total-item-count type
      trace: (string) ~>
        @_trace string
    )

  _trace: (string) ->
    if @log-path?
      fs.write-file @log-path, string

  _create-script: (code) ->
    try
      new Script code, @_get-filename()
    catch err
      @_code-error err

  _get-filename: ->
    @_filename ?= "#{@bot-id}.bot.js"
