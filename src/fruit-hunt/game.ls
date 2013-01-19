{BoardFactory,ContextFactory} = require '../fruit-hunt'

exports.Game = class Game

  @play = (bot1, bot2, opts) ->
    instance = new this(bot1, bot2, opts)
    instance.play

  @TURN_LIMIT = 1000000

  (@bot1, @bot2, {max-size,min-size}:board-options={}) ->
    unless @bot1? && @bot2?
      throw new Error "Missing mandatory arg: please supply 2 bots"

    @board = BoardFactory.create-board do
      max-size: max-size
      min-size: min-size
      bot-ids: [@bot1.id, @bot2.id]

    @_assign-context @bot1
    @_assign-context @bot2

    @_turn-count = 0

  # FIXME this should be in Bot... here, we should just be calling bot.initialize(@board),
  # so the bot knows how to prepare itself for the game
  _assign-context: (bot) ->
    cf = new ContextFactory bot: bot, board: @board
    bot.set-new-context cf.get-context()
    bot.new-game()

  do-turn: ~>
    moves = {}
    moves[@bot1.id] = @bot1.make-move()
    moves[@bot2.id] = @bot2.make-move()
    ++@_turn-count
    @board.handle-turn moves

  get-winner: ->
    if @_turn-count >= @@TURN_LIMIT
      false
    else
      @board.get-winner()

  play: ->
    until (winner = @get-winner())?
      @do-turn!
    @bot1.reset-context()
    @bot2.reset-context()
    winner
