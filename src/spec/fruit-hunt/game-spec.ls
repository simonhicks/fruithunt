should = require \should
_ = require \underscore
vm = require \vm

{BoardFactory,Game,Board,ContextFactory,Bot} = require '../../fruit-hunt'

with-stub = (klass, method, stub-fn, code) ->
  old-impl = klass::[method]
  klass::[method] = stub-fn
  code()
  klass::[method] = old-impl

make-bot = (id, code) ->
  new Bot id: id, code: code

suite 'Game', ->
  setup ->
    function make_move
      if get_board()[get_my_x()][get_my_y()]
        TAKE
      else
        [NORTH, EAST, SOUTH, WEST][Math.random() |> (* 4) |> Math.floor]

    @bill = make-bot 'Bill', make_move.to-string()

    @bob = make-bot 'Bob', make_move.to-string()

  test "uses the constructor args to create a board containing the bots", ->
    @game = new Game @bill, @bob
    @game.board.should.be.an.instance-of Board

  test "uses the constructor args to construct a context for each bot", ->
    @game = new Game @bill, @bob
    @game.bot1.get-context().should.not.eql null
    @game.bot2.get-context().should.not.eql null

  test "should pass a bot's id & log-path through to the context factory", ->
    stub = ->
      vm.create-context log-path: @log-path, bot-id: @bot-id

    @bill.log-path = 'path-to-log.txt'
    with-stub ContextFactory, 'getContext', stub, ~>
      @game = new Game @bill, @bob
      @bill.get-context().log-path.should.equal @bill.log-path
      @bill.get-context().bot-id.should.equal @bill.id

  test "throws an error when there are less than 2 bots", ->
    (-> new Game @bill).should.throw-error(/2 bots/)

  test 'should call new_game() on each bot-executor at the start of each game', ->
    @bob = make-bot 'Bob', '''
      function make_move() { return null; }
      function new_game() { bob_new_game_called = true; }
      '''
    @bill = make-bot 'Bill', '''
      function make_move() { return null; }
      function new_game() { bill_new_game_called = true; }
      '''

    @game = new Game @bill, @bob

    @bill.get-context().bill_new_game_called.should.equal true
    @bob.get-context().bob_new_game_called.should.equal true

  test 'should call make-move() once on each bot for each turn', ->
    var make-move-called
    counter = function make_move
      if typeof make-move-called == 'undefined'
        make-move-called := 0;
      make-move-called := make-move-called + 1
      EAST

    @bill = make-bot 'Bill', counter.to-string()
    @bob = make-bot 'Bob', counter.to-string()

    @game = new Game @bill, @bob
    _.times 3, @game.do-turn

    @bill.get-context().make-move-called.should.equal 3
    @bob.get-context().make-move-called.should.equal 3

  test 'should pass the result of make-move on to the board', ->
    mm = -> "function make_move(){ return '#{it}'; }"
    game = new Game make-bot(\Bill, mm \Bill), make-bot(\Bob, mm \Bob)

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

  test 'should declare a game to be a draw after TURN_LIMIT moves', ->
    Game.TURN_LIMIT = 3
    @game = new Game @bill, @bob
    # after 2 turns there's no winner
    _.times 2, ~> @game.do-turn()
    (@game.get-winner() == undefined).should.equal true
    # ... but after a third, the limit has been reached, so it's a draw
    @game.do-turn()
    @game.get-winner().should.equal false

  test "should reset bot context's after a bot has won", ->
    @game = new Game @bill, @bob
    stub = ~> @bill.id

    with-stub Board, 'getWinner', stub, ~>
      @game.play()
      (@bill.get-context() == null).should.equal true
      (@bob.get-context() == null).should.equal true
