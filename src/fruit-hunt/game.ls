{BoardFactory,BotExecutor} = require '../fruit-hunt'

exports.Game = class Game

  @play = (bot1, bot2, opts) ->
    instance = new this(bot1, bot2, opts)
    instance.play

  @TURN_LIMIT = 1000000

  (player1, player2, {max-size,min-size}:board-options={}) ->
    unless player1? && player2?
      throw new Error "Missing mandatory arg: please supply 2 bots"

    @board = BoardFactory.create-board do
      max-size: max-size
      min-size: min-size
      bot-ids: [player1.id, player2.id]

    @player1 = @_create-bot-executor player1
    @player2 = @_create-bot-executor player2

    @_turn-count = 0

  _create-bot-executor: ({id,code,log-path}:bot-options={}) ->
    bot-exec = new BotExecutor do
      bot-id: id
      code: code
      log-path: log-path
      board: @board
    bot-exec.new-game()
    bot-exec

  do-turn: ->
    moves = {}
    moves[@player1.bot-id] = @player1.make-move()
    moves[@player2.bot-id] = @player2.make-move()
    @board.handle-turn moves

  get-winner: ->
    if ++@_turn-count >= @@TURN_LIMIT
      false
    else
      @board.get-winner()

  play: ->
    until (winner = @get-winner())?
      @do-turn!
    winner
