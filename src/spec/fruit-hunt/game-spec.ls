should = require \should
_ = require \underscore

{BoardFactory,Game,Board,BotExecutor} = require '../../fruit-hunt'

with-stub = (klass, method, stub-fn, code) ->
  old-impl = klass::[method]
  klass::[method] = stub-fn
  code()
  klass::[method] = old-impl

suite 'Game', ->
  setup ->
    function make_move
      if get_board()[get_my_x()][get_my_y()]
        TAKE
      else
        [NORTH, EAST, SOUTH, WEST][Math.random() |> (* 4) |> Math.floor]

    @bill =
      id: 'Bill'
      code: make_move.to-string()

    @bob =
      id: 'Bob'
      code: make_move.to-string()

  test "uses the constructor args to create a board containing the bots", ->
    @game = new Game @bill, @bob
    @game.board.should.be.an.instance-of Board

  test "uses the constructor args to construct bot executors", ->
    @game = new Game @bill, @bob
    @game.player1.should.be.an.instance-of BotExecutor
    @game.player2.should.be.an.instance-of BotExecutor

  test "throws an error when there are less than 2 bots", ->
    (-> new Game @bill).should.throw-error(/2 bots/)

  test 'should call new_game() on each bot-executor at the start of each game', ->
    stub = ->
      @new-game-called = true

    with-stub BotExecutor, 'newGame', stub, ~>
      @game = new Game @bill, @bob

    @game.player1.new-game-called.should.equal true
    @game.player2.new-game-called.should.equal true

  test 'should call make-move() once on each bot for each turn', ->
    counter = ->
      @make-move-called ?= 0;
      @make-move-called++
      Board.EAST

    with-stub BotExecutor, 'makeMove', counter, ~>
      @game = new Game @bill, @bob
      @game.do-turn()
      @game.do-turn()
      @game.do-turn()

    @game.player1.make-move-called.should.equal 3
    @game.player2.make-move-called.should.equal 3

  test 'should pass the result of make-move on to the board', ->
    make-bot = (id) ->
      id: id
      code: "function make_move(){ return '#id'; }"
    game = new Game make-bot(\Bill), make-bot(\Bob)

    var received
    result-storer = (stuff) ->
      received := stuff

    with-stub Board, 'handleTurn', result-storer, ~>
      game.do-turn()

    received.should.eql Bob: \Bob Bill: \Bill

  test 'should delegate calls to get-winner to the board', ->
    count = 0
    counter = ->
      ++count

    with-stub Board, 'getWinner', counter, ~>
      @game = new Game @bill, @bob
      @game.get-winner()
      @game.get-winner()

    count.should.equal 2

  test 'should abandon a game after TURN_LIMIT moves', ->
    count = 0
    counter = ->
      ++count

    with-stub Board, 'getWinner', counter, ~>
      @game = new Game @bill, @bob
      @game._turn-count = Game.TURN_LIMIT
      @game.get-winner().should.equal false
      count.should.equal 0
