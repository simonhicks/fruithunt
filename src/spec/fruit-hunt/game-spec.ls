should = require \should

{Game} = require '../../lib/fruit-hunt'

suite 'Game', ->
  suite 'newly created', ->
    board = [
      [0, 1],
      [0, 0]
    ]

    setup ->
      @game = new Game board

    suite 'managing the board', ->
      test 'should clone the board it is given', ->
        @game._board.should.not.equal board
        @game._board.should.eql board

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
      [0, 1, 0],
      [0, 0, 0]
    ]
    name = 'bobby'

    setup ->
      @game = new Game board
      @game.add-bot name, [1, 1]

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
      @game = new Game board
      @game.add-bot name, [0, 0]

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
      @game = new Game board
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

  suite 'managing items', ->
    board = [
      [0, 0, 1, 1],
      [0, 0, 2, 2],
      [0, 0, 0, 3],
      [0, 0, 0, 4]
    ]

    setup ->
      @game = new Game board

    test 'should know what types of item there are in the game', ->
      @game._types.should.eql [1, 2, 3, 4]

    test 'should know how many items of each type there are remaining', ->
      @game.get-item-count 1 .should.equal 2
      @game.set-item-at [2, 0], 0
      @game.get-item-count 1 .should.equal 1
      @game.set-item-at [3, 0], 0
      @game.get-item-count 1 .should.equal 0

    test "should remember what types there are, even after they've been taken", ->
      @game.set-item-at [3, 2], 0
      @game.set-item-at [3, 3], 0
      @game.get-item-count 3 .should.equal 0
      @game.get-item-count 4 .should.equal 0
      @game._types.should.eql [1, 2, 3, 4]

  suite 'calculating the winner', ->
    suite 'for an individual type', ->
      bill = \Bill
      ben = \Ben

      suite 'with only one item type', ->
        setup ->
          @game = new Game [
            [0, 0, 1],
            [0, 0, 1],
            [0, 0, 1]
          ]
          @game.add-bot bill, [0, 0]
          @game.add-bot ben, [0, 0]

        test 'when bill or ben can win', ->
          should.not.exist @game.get-winner!

        test 'when bill has already won', ->
          for i in [1 to 4]
            @game.award-point bill, 1
          @game.get-winner!.should.equal bill

        test "when bill can win or draw, but ben can't win", ->
          for i in [1 to 3]
            @game.award-point bill, 1
          should.not.exist @game.get-winner!

      suite 'with 3 item types', ->
        setup ->
          @game = new Game [
            [0, 0, 1],
            [0, 0, 2],
            [0, 0, 3]
          ]
          @game.add-bot bill, [0, 0]
          @game.add-bot ben, [0, 0]

        test 'when bill or ben can win', ->
          should.not.exist @game.get-winner!

        test 'when bill has already won', ->
          for i in [1 to 2]
            @game.award-point bill, 1 # bill has won type 1
            @game.award-point bill, 2 # bill has won type 2
          @game.get-winner!.should.equal bill

        test "when bill can win or draw, but ben can't win", ->
          for i in [1 to 2]
            @game.award-point bill, 1 # bill has won type 1
          @game.award-point bill, 2 # bill can win or draw type 2
          should.not.exist @game.get-winner!

        test "when it's finished and it's a draw", ->
          @game = new Game [[1, 0], [0, 0]]
          @game.add-bot bill, [0, 0], {}
          @game.add-bot ben, [0, 0], {}
          @game.handle-takes [bill]
          @game.award-point ben, 2
          @game.get-winner!.should.equal false

  suite 'handling invalid situations', ->
    test 'should throw an exception when there are no items in the board', ->
      board-without-items = [[0, 0], [0, 0]]
      (-> new Game board-without-items).should.throw!

    test 'should throw an exception when there are more than 2 bots', ->
      game = new Game [[0, 0], [0, 1]]
      game.add-bot \a, [0, 0]
      game.add-bot \b, [0, 0]
      (-> game.add-bot \c, [0, 0]).should.throw!
