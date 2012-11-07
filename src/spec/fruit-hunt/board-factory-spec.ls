should = require \should
_ = require \underscore

{BoardFactory, Board} = require '../../fruit-hunt'

class ControlledRandom
  (@next-random = null) ->
  set-next: (n) ~> @next-random := n
  get-next: ~> @next-random ? Math.random()

MIN_ARGS = bot-ids: <[bill ben]>

args-with = (additional-args={}) ->
  args = {}
  args <<< MIN_ARGS
  args <<< additional-args

suite "BoardFactory", ->
  suite '.create-board()', ->
    test 'should create a board with the default min/max size values', ->
      board = BoardFactory.create-board(args-with())
      board.should.be.an.instance-of Board

    test 'should pass size configuration options through to the board-factory', ->
      size = 10
      board = BoardFactory.create-board args-with(min-size: size, max-size: size)
      board.get-width().should.equal size
      board.get-height().should.equal size

    test 'should pass bot-ids through to the board-factory', ->
      args = args-with()
      board = BoardFactory.create-board(args)
      _.keys board._bots .should.eql args.bot-ids

  suite 'creating random numbers', ->
    test 'should have Math.random() aliased to BoardFactory.random()', ->
      BoardFactory::random.should.equal Math.random

  suite 'when being constructed', ->
    setup ->
      @opts =
        max-size: 20
        min-size: 2
        bot-ids:  <[ bill ben ]>

      @construct-board-factory = ->
        new BoardFactory @opts

    test 'should allow min size and max size to be configured through named args', ->
      factory = @construct-board-factory()
      factory.min-size.should.equal @opts.min-size
      factory.max-size.should.equal @opts.max-size

    test 'should be initialized with a default max and a min size', ->
      @opts <<< max-size: null, min-size: null
      factory = @construct-board-factory()
      factory.min-size.should.equal 5
      factory.max-size.should.equal 15

    test 'should throw an error if less than 2 bot ids are supplied on construction', ->
      @opts <<< bot-ids: <[ bill ]>
      @construct-board-factory.should.throw-error /bot-ids/

    test 'should throw an error if more than 2 bot ids are supplied on construction', ->
      @opts <<< bot-ids: <[ bill ben daisy]>
      @construct-board-factory.should.throw-error /bot-ids/

  suite 'creating a random board', ->
    setup ->
      @args = args-with()
      @factory = new BoardFactory @args
      @rnd = new ControlledRandom
      @factory.random = @rnd.get-next

    test 'should create a board <= MAX_SIZE', ->
      @rnd.set-next 1
      @factory.initialize-cells()
      @factory.cells.should.have.length 15
      _.all @factory.get-cells(), (-> it.should.have.length 15)

    test 'should create a board >= MIN_SIZE', ->
      @rnd.set-next 0
      @factory.initialize-cells()
      @factory.get-cells().should.have.length 5
      _.all @factory.get-cells(), (-> it.should.have.length 5)

    test 'should add the specified bots to the board', ->
      _.keys @factory.get-board()._bots .should.eql @args.bot-ids

  suite 'adding items to the board', ->
    test 'number of item types squared should be less than number of squares in the board', ->
      lo-rand = new ControlledRandom 0

      test-number-of-types = (size) ~>
        args = args-with min-size: size, max-size: size
        factory = new BoardFactory args
        factory.random = lo-rand.get-next
        factory.get-types().length.should.be.below size

      test-number-of-types 10
      test-number-of-types 5

    test 'for item type i, there should be `(i - 1) * 2 + 1` items', ->
      factory = new BoardFactory args-with()
      cells = factory.get-cells()
      types = factory.get-types()
      get-item-count = (type) ->
        _.chain cells .flatten() .countBy (-> it) .value()[type] ? 0
      for i in types
        get-item-count i .should.equal (i - 1) * 2 + 1

    test 'items should be randomly distributed', ->
      cells1 = new BoardFactory(args-with()).get-cells()
      cells2 = new BoardFactory(args-with()).get-cells()
      cells1.should.not.eql cells2

  suite 'adding bots to the board', ->
    test 'should ensure bots do not start on an item', ->
      args = args-with()
      factory = new BoardFactory(args)
      factory.cells = [
        [1, 1],
        [1, 0]
      ]
      factory.width = factory.height = 2
      bot-id = args.bot-ids[0]
      factory.get-board().get-position(bot-id).should.eql {x: 1, y: 1}

    test 'should ensure both bots start in the same place', ->
      args = args-with()
      factory = new BoardFactory args
      board = factory.get-board()
      [bot1, bot2] = args.bot-ids
      board.get-position bot1 .should.eql board.get-position bot2

