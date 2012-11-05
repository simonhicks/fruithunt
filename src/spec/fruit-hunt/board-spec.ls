should = require \should

{Board} = require '../../fruit-hunt'

suite 'Board', ->
  suite 'newly created', ->
    cells = [
      [0, 1],
      [0, 0]
    ]

    setup ->
      @game = new Board cells

    suite 'managing the cells', ->
      test 'should clone the cells it is given', ->
        @game._cells.should.not.equal cells
        @game._cells.should.eql cells

      test 'should know the item at each board location', ->
        @game.get-item-at [0, 0] .should.equal 0
        @game.get-item-at [1, 0] .should.equal 1

      test 'should be able to clear the item at a board location', ->
        position = [1, 0]
        @game.get-item-at position .should.equal 1
        @game._clear-item-at position
        @game.get-item-at position .should.equal 0

    suite 'managing bots', ->
      name = 'Bobby'
      bobby = {}
      position = [0, 0]

      setup ->
        @game.add-bot name, position, bobby

      test "should store bots by name", ->
        @game._get-bot name .should.equal bobby

      test "should keep track of a bot's position", ->
        @game.get-position name .should.eql position

  suite 'moving bots', ->
    cells = [
      [0, 0, 0],
      [0, 1, 0],
      [0, 0, 0]
    ]
    name = 'bobby'

    setup ->
      @game = new Board cells
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
    cells = [
      [0, 1],
      [2, 3]
    ]
    name = 'Bobby'

    setup ->
      @game = new Board cells
      @game.add-bot name, [0, 0]

    test 'should start all bots with 0 for all items', ->
      @game.get-score name, 1 .should.equal 0
      @game.get-score name, 2 .should.equal 0
      @game.get-score name, 3 .should.equal 0

    test 'should be able to add full points to a bot', ->
      @game.get-score name, 1 .should.equal 0
      @game.get-score name, 2 .should.equal 0
      @game._award-point name, 1
      @game.get-score name, 1 .should.equal 1
      @game.get-score name, 2 .should.equal 0

    test 'should be able to add half points to a bot', ->
      @game.get-score name, 1 .should.equal 0
      @game.get-score name, 2 .should.equal 0
      @game._award-point name, 1, true
      @game.get-score name, 1 .should.equal 0.5
      @game.get-score name, 2 .should.equal 0

  suite 'handling bot decisions', ->
    cells = [
      [1, 0, 1],
      [0, 1, 0],
      [2, 0, 0]
    ]
    bill = \Bill
    ben = \Ben
    start = [0, 0]

    setup ->
      @decisions = {}
      @game = new Board cells
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
        @game._set-position bill, position

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
        @game._set-position bill, item1
        @game._set-position ben, item1
        @decisions[bill] = @decisions[ben] = \take
        @game.handle-turn @decisions
        @game.get-score bill, 1 .should.equal 0.5
        @game.get-score ben, 1 .should.equal 0.5

      test "should award a full point each when both bot's take different items", ->
        @game._set-position bill, item1
        @game._set-position ben, item2
        @decisions[bill] = @decisions[ben] = \take
        @game.handle-turn @decisions
        @game.get-score bill, 1 .should.equal 1
        @game.get-score ben, 2 .should.equal 1

  suite 'managing items', ->
    cells = [
      [0, 0, 1, 1],
      [0, 0, 2, 2],
      [0, 0, 0, 3],
      [0, 0, 0, 4]
    ]

    setup ->
      @game = new Board cells

    test 'should know what types of item there are in the game', ->
      @game._types.should.eql [1, 2, 3, 4]

    test 'should know how many items of each type there are remaining', ->
      @game._get-item-count 1 .should.equal 2
      @game._clear-item-at [2, 0]
      @game._get-item-count 1 .should.equal 1
      @game._clear-item-at [3, 0]
      @game._get-item-count 1 .should.equal 0

    test "should remember what types there are, even after they've been taken", ->
      @game._clear-item-at [3, 2]
      @game._clear-item-at [3, 3]
      @game._get-item-count 3 .should.equal 0
      @game._get-item-count 4 .should.equal 0
      @game._types.should.eql [1, 2, 3, 4]

  suite 'calculating the winner', ->
    suite 'for an individual type', ->
      bill = \Bill
      ben = \Ben

      suite 'with only one item type', ->
        setup ->
          @game = new Board [
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
            @game._award-point bill, 1
          @game.get-winner!.should.equal bill

        test "when bill can win or draw, but ben can't win", ->
          for i in [1 to 3]
            @game._award-point bill, 1
          should.not.exist @game.get-winner!

        test "when it's finished and it's a draw", ->
          game = new Board [[1, 0], [0, 0]]
          game.add-bot bill, [0, 0]
          game.add-bot ben, [0, 0]
          game._handle-takes [bill, ben]
          game.get-winner!.should.equal false

        test 'checks all items types (including ones which have all been removed from the board', ->
          game = new Board [[1, 0], [0, 0]]
          game.add-bot bill, [0, 0]
          game.add-bot ben, [0, 0]
          game._handle-takes [bill]
          game.get-winner!.should.equal bill

      suite 'with 3 item types', ->
        setup ->
          @game = new Board [
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
            @game._award-point bill, 1 # bill has won type 1
            @game._award-point bill, 2 # bill has won type 2
          @game.get-winner!.should.equal bill

        test "when bill can win or draw, but ben can't win", ->
          for i in [1 to 2]
            @game._award-point bill, 1 # bill has won type 1
          @game._award-point bill, 2 # bill can win or draw type 2
          should.not.exist @game.get-winner!

  suite 'handling invalid situations', ->
    test 'should throw an exception when there are no items in the board', ->
      cells-without-items = [[0, 0], [0, 0]]
      (-> new Board cells-without-items).should.throw!

    test 'should throw an exception when there are more than 2 bots', ->
      game = new Board [[0, 0], [0, 1]]
      game.add-bot \a, [0, 0]
      game.add-bot \b, [0, 0]
      (-> game.add-bot \c, [0, 0]).should.throw!
