should = require \should
_ = require \underscore

{Tournament,Game,Bot} = require '../../fruit-hunt'

suite 'Tournament', ->
  function make_move
    if get_board()[get_my_x()][get_my_y()]
      TAKE
    else
      [NORTH, EAST, SOUTH, WEST][Math.random() |> (* 4) |> Math.floor]

  setup ->
    code = make_move.to-string()

    @bots =
      * new Bot id: 'bot-1', code: code
      * new Bot id: 'bot-2', code: code
      * new Bot id: 'bot-3', code: code
      * new Bot id: 'bot-4', code: code

    @min-opts = bots: @bots
    @create-instance = (opts={}) ~>
      new Tournament(_.extend @min-opts, opts)

  suite 'when newly created', ->
    test 'requires a collection of bots', ->
      valid-instance = @create-instance()
      valid-instance.get-bots().should.have.length-of @bots.length
      (~> @create-instance bots: null).should.throw-error /\bbots\b/i

    test 'requires at least 2 bots', ->
      (~> @create-instance bots: [@bots[0]]).should.throw-error /at least (2|two) bots/i
      (~> @create-instance bots: []).should.throw-error /at least (2|two) bots/i

    test 'only accepts Bot instances in the bots collection', ->
      (~> @create-instance bots: [1, 2]).should.throw-error /\bBot\b/

    test 'has a default value of games per round', ->
      @create-instance(rounds: null).should.have.property('rounds', Tournament.DEFAULT_ROUNDS)

    test 'accepts a number of games per round', ->
      n = 2
      tournament = @create-instance rounds: n
      tournament.should.have.property('rounds', n)

    test 'accepts board options', ->
      opts = {}
      tournament = @create-instance board-options: opts
      tournament.should.have.property('boardOptions', opts)

    test "doesn't apply a default set of board options", ->
      tournament = @create-instance board-options: null
      should.not.exist tournament.board-options

  suite 'when playing', ->
    setup ->
      @with-stubbed-game = (code) ->
        old-play = Game.play
        Game.play = (...args) ->
          @call-list ?= []
          @call-list.push args
          args.sort()[1].id
        code()
        Game.play = old-play

      @bots =
        * new Bot id: \a code: make_move.to-string()
        * new Bot id: \b code: make_move.to-string()
        * new Bot id: \c code: make_move.to-string()
        * new Bot id: \d code: make_move.to-string()
      @rounds = 3
      @board-options = foo: \foo
      @tourney = @create-instance rounds: @rounds, bots: @bots, board-options: @board-options

    test 'makes each bot play each other bot N times', ->
      # each bot plays each other bot twice...
      expected-games = @rounds * _.reduce [@bots.length - 1 to 1 by -1], (+), 0

      @with-stubbed-game ~>
        @tourney.play()
        Game.call-list.should.have.length expected-games

    test 'ranks the bots in the order of the number of games they won', ->
      # the bot with the alphabetically later id wins
      expected-order = _.map @bots, (.id) .reverse

      @with-stubbed-game ~>
        @tourney.play()
        sorted-ids = _.map @tourney.get-results(), (.id)
        sorted-ids.should.eql expected-order

    test 'passes the board options through to the game', ->
      @with-stubbed-game ~>
        @tourney.play()
        game-args = Game.call-list[0]
        game-args[2].should.eql @board-options
