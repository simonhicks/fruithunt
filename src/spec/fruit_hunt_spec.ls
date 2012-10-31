should = require \should

{FruitHunt} = require '../lib/fruit_hunt'

suite 'FruitHunt', ->
  suite 'newly created', ->
    board = [
      [0, 1],
      [0, 0]
    ]

    setup ->
      @game = new FruitHunt board

    suite 'managing the board', ->
      test 'should clone the board it is given', ->
        @game.board.should.not.equal board
        @game.board.should.eql board

      test 'should know the item at each board location', ->
        @game.get-item-at [0, 0] .should.equal 0
        @game.get-item-at [1, 0] .should.equal 1

      test 'should be able to set the item at a board location', ->
        position = [0, 0]
        @game.get-item-at position .should.equal 0
        @game.set-item-at position, 2
        @game.get-item-at position .should.equal 2
        @game.set-item-at position, null
        @game.get-item-at position .should.equal 0

    suite 'managing bots', ->
      name = 'Bobby'
      bobby = {}
      position = [0, 0]

      setup ->
        @game.add-bot name, position, bobby

      test "should store bots by name", ->
        @game.get-bot name .should.equal bobby

      test "should keep track of a bot's position", ->
        @game.get-position name .should.eql position

  suite 'moving bots', ->
    board = [
      [0, 0, 0],
      [0, 0, 0],
      [0, 0, 0]
    ]
    name = 'bobby'

    setup ->
      @game = new FruitHunt board
      @game.add-bot name, [1, 1], {}

    test 'should be able to move a bot north', ->
      @game.move-bot name, \north
      @game.get-position name .should.eql [1, 0]

    test 'should be able to move a bot east', ->
      @game.move-bot name, \east
      @game.get-position name .should.eql [2, 1]

    test 'should be able to move a bot south', ->
      @game.move-bot name, \south
      @game.get-position name .should.eql [1, 2]

    test 'should be able to move a bot west', ->
      @game.move-bot name, \west
      @game.get-position name .should.eql [0, 1]

    test "shouldn't move a bot if it would go over the edge of the board", ->
      @game.move-bot name, \west
      @game.get-position name .should.eql [0, 1]
      @game.move-bot name, \west
      @game.get-position name .should.eql [0, 1]

  suite 'tracking bot scores', ->
    board = [
      [0, 1],
      [2, 3]
    ]
    name = 'Bobby'

    setup ->
      @game = new FruitHunt board
      @game.add-bot name, [0, 0], {}

    test 'should start all bots with 0 for all items', ->
      @game.get-score name, 1 .should.equal 0
      @game.get-score name, 2 .should.equal 0
      @game.get-score name, 3 .should.equal 0

    test 'should be able to add full points to a bot', ->
      @game.get-score name, 1 .should.equal 0
      @game.get-score name, 2 .should.equal 0
      @game.award-point name, 1
      @game.get-score name, 1 .should.equal 1
      @game.get-score name, 2 .should.equal 0

    test 'should be able to add half points to a bot', ->
      @game.get-score name, 1 .should.equal 0
      @game.get-score name, 2 .should.equal 0
      @game.award-point name, 1, true
      @game.get-score name, 1 .should.equal 0.5
      @game.get-score name, 2 .should.equal 0

  suite 'handling bot decisions', ->
    board = [
      [1, 0, 1],
      [0, 1, 0],
      [2, 0, 0]
    ]
    bill = \Bill
    ben = \Ben
    start = [0, 0]

    setup ->
      @decisions = {}
      @game = new FruitHunt board
      @game.add-bot bill, start, {}
      @game.add-bot ben, start, {}

    test "should handle multiple bot's moves at once", ->
      @decisions[bill] = \east
      @decisions[ben] = \south
      @game.handle-turn @decisions
      @game.get-position bill .should.eql [1, 0]
      @game.get-position ben .should.eql [0, 1]

    suite 'when a single bot takes an item', ->
      position = [0, 0]

      setup ->
        @game.set-position bill, position

      test "should award a full point", ->
        @game.get-score bill, 1 .should.equal 0
        @decisions[bill] = \take
        @game.handle-turn @decisions
        @game.get-score bill, 1 .should.equal 1

      test "should empty the square", ->
        @game.get-item-at position .should.equal 1
        @decisions[bill] = \take
        @game.handle-turn @decisions
        @game.get-item-at position .should.equal 0

    suite "when more than one bot takes an item at the same time", ->
      item1 = [0, 0]
      item2 = [0, 2]

      test "should award half a point each when they take the same item", ->
        @game.set-position bill, item1
        @game.set-position ben, item1
        @decisions[bill] = @decisions[ben] = \take
        @game.handle-turn @decisions
        @game.get-score bill, 1 .should.equal 0.5
        @game.get-score ben, 1 .should.equal 0.5

      test "should award a full point each when both bot's take different items", ->
        @game.set-position bill, item1
        @game.set-position ben, item2
        @decisions[bill] = @decisions[ben] = \take
        @game.handle-turn @decisions
        @game.get-score bill, 1 .should.equal 1
        @game.get-score ben, 2 .should.equal 1

  suite 'calculating the winner', ->
