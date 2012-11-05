should = require \should
_ = require \underscore

{BoardFactory, Board} = require '../../fruit-hunt'

class ControlledRandom
  (@next-random = null) ->
  set-next: (n) ~> @next-random := n
  get-next: ~> @next-random ? Math.random!

suite "BoardFactory", ->
  suite '.create-board()', ->
    test 'should create a board with the default min/max size values', ->
      board = BoardFactory.create-board!
      board.should.be.an.instance-of Board

    test 'should have configurable min/max size', ->
      size = 10
      board = BoardFactory.create-board min-size: size, max-size: size
      board.get-width!.should.equal size
      board.get-height!.should.equal size

  suite 'creating random numbers', ->
    test 'should have Math.random() aliased to BoardFactory.random()', ->
      BoardFactory::random.should.equal Math.random

  suite 'creating a random board', ->
    setup ->
      @factory = new BoardFactory
      @rnd = new ControlledRandom
      @factory.random = @rnd.get-next

    test 'should be initialized with a max and a min size', ->
      @factory.min-size.should.equal 5
      @factory.max-size.should.equal 15

    test 'should create a board <= MAX_SIZE', ->
      @rnd.set-next 1
      @factory.initialize-cells!
      @factory.cells.should.have.length 15
      _.all @factory.get-cells!, (-> it.should.have.length 15)

    test 'should create a board >= MIN_SIZE', ->
      @rnd.set-next 0
      @factory.initialize-cells!
      @factory.get-cells!.should.have.length 5
      _.all @factory.get-cells!, (-> it.should.have.length 5)

  suite 'adding items to the board', ->
    test 'number of item types squared should be less than number of squares in the board', ->
      lo-rand = new ControlledRandom 0
      test-number-of-types = (size) ~>
        factory = new BoardFactory size, size
        factory.random = lo-rand.get-next
        factory.get-types!.length.should.be.below size

      test-number-of-types 10
      test-number-of-types 5

    test 'for item type i, there should be `(i * 2) + 1` items', ->
      factory = new BoardFactory
      cells = factory.get-cells!
      types = factory.get-types!
      get-item-count = (type) ->
        _.chain cells .flatten! .countBy (-> it) .value![type] ? 0
      for i in types
        get-item-count i .should.equal i * 2 + 1

    test 'items should be randomly distributed', ->
      cells1 = new BoardFactory! .get-cells!
      cells2 = new BoardFactory! .get-cells!
      cells1.should.not.eql cells2
