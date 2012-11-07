should = require \should

{Board} = require '../../fruit-hunt'
{NORTH,EAST,SOUTH,WEST,TAKE,PASS} = Board

suite 'Board', ->
  suite 'newly created', ->
    cells = [
      [0, 1],
      [0, 0]
    ]

    setup ->
      @board = new Board cells

    suite 'managing the cells', ->
      test 'should clone the cells it is given', ->
        @board.get-board().should.eql cells
        @board.get-board().should.not.equal cells

      test 'should know the item at each board location', ->
        @board.get-item-at {x: 0, y: 0} .should.equal 0
        @board.get-item-at {x: 0, y: 1} .should.equal 1

      test 'should be able to clear the item at a board location', ->
        position = {x: 0, y: 1}
        @board.get-item-at position .should.equal 1
        @board._clear-item-at position
        @board.get-item-at position .should.equal 0

    suite 'managing bots', ->
      bobby = 'Bobby'
      billy = 'Billy'
      position = {x: 0, y: 0}

      setup ->
        @board.add-bot bobby, position
        @board.add-bot billy, position

      test "should store bots by name", ->
        @board.has-bot bobby .should.equal true

      test "should keep track of a bot's position", ->
        @board.get-position bobby .should.eql position

      test "should know a who a bot's opponent is", ->
        @board.get-opponent bobby .should.equal billy
        @board.get-opponent billy .should.equal bobby

  suite 'moving bots', ->
    cells = [
      [0, 0, 0],
      [0, 1, 0],
      [0, 0, 0]
    ]
    name = 'bobby'

    setup ->
      @board = new Board cells
      @board.add-bot name, {x: 1, y: 1}

    test 'should be able to move a bot north', ->
      @board.move-bot name, NORTH
      @board.get-position name .should.eql {x: 1, y: 0}

    test 'should be able to move a bot east', ->
      @board.move-bot name, EAST
      @board.get-position name .should.eql {x: 2, y: 1}

    test 'should be able to move a bot south', ->
      @board.move-bot name, SOUTH
      @board.get-position name .should.eql {x: 1, y: 2}

    test 'should be able to move a bot west', ->
      @board.move-bot name, WEST
      @board.get-position name .should.eql {x: 0, y: 1}

    test "shouldn't move a bot if it would go over the edge of the board", ->
      @board.move-bot name, WEST
      @board.get-position name .should.eql {x: 0, y: 1}
      @board.move-bot name, WEST
      @board.get-position name .should.eql {x: 0, y: 1}

  suite 'tracking bot scores', ->
    cells = [
      [0, 1],
      [2, 3]
    ]
    name = 'Bobby'

    setup ->
      @board = new Board cells
      @board.add-bot name, {x: 0, y: 0}

    test 'should start all bots with 0 for all items', ->
      @board.get-score name, 1 .should.equal 0
      @board.get-score name, 2 .should.equal 0
      @board.get-score name, 3 .should.equal 0

    test 'should be able to add full points to a bot', ->
      @board.get-score name, 1 .should.equal 0
      @board.get-score name, 2 .should.equal 0
      @board._award-point name, 1
      @board.get-score name, 1 .should.equal 1
      @board.get-score name, 2 .should.equal 0

    test 'should be able to add half points to a bot', ->
      @board.get-score name, 1 .should.equal 0
      @board.get-score name, 2 .should.equal 0
      @board._award-point name, 1, true
      @board.get-score name, 1 .should.equal 0.5
      @board.get-score name, 2 .should.equal 0

  suite 'handling bot decisions', ->
    cells = [
      [1, 0, 1],
      [0, 1, 0],
      [2, 0, 0]
    ]
    bill = \Bill
    ben = \Ben
    start = {x: 0, y: 0}

    setup ->
      @decisions = {}
      @board = new Board cells
      @board.add-bot bill, start, {}
      @board.add-bot ben, start, {}

    test "should handle multiple bot's moves at once", ->
      @decisions[bill] = EAST
      @decisions[ben] = SOUTH
      @board.handle-turn @decisions
      @board.get-position bill .should.eql {x: 1, y: 0}
      @board.get-position ben .should.eql {x: 0, y: 1}

    suite 'when a single bot takes an item', ->
      position = {x: 0, y: 0}

      setup ->
        @board._set-position bill, position

      test "should award a full point", ->
        @board.get-score bill, 1 .should.equal 0
        @decisions[bill] = TAKE
        @board.handle-turn @decisions
        @board.get-score bill, 1 .should.equal 1

      test "should empty the square", ->
        @board.get-item-at position .should.equal 1
        @decisions[bill] = TAKE
        @board.handle-turn @decisions
        @board.get-item-at position .should.equal 0

    suite "when more than one bot takes an item at the same time", ->
      item1 = {x: 0, y: 0}
      item2 = {x: 2, y: 0}

      test "should award half a point each when they take the same item", ->
        @board._set-position bill, item1
        @board._set-position ben, item1
        @decisions[bill] = @decisions[ben] = TAKE
        @board.handle-turn @decisions
        @board.get-score bill, 1 .should.equal 0.5
        @board.get-score ben, 1 .should.equal 0.5

      test "should award a full point each when both bot's take different items", ->
        @board._set-position bill, item1
        @board._set-position ben, item2
        @decisions[bill] = @decisions[ben] = TAKE
        @board.handle-turn @decisions
        @board.get-score bill, 1 .should.equal 1
        @board.get-score ben, 2 .should.equal 1

  suite 'managing items', ->
    cells = [
      [0, 0, 1, 1],
      [0, 0, 2, 2],
      [0, 0, 0, 3],
      [0, 0, 0, 4]
    ]

    setup ->
      @board = new Board cells

    test 'should know what types of item there are in the board', ->
      @board._types.should.eql [1, 2, 3, 4]

    test "should know how many of each item there are, even after they're taken", ->
      @board.get-total-item-count 1 .should.equal 2
      @board.get-total-item-count 2 .should.equal 2
      @board.get-total-item-count 3 .should.equal 1
      @board.get-total-item-count 4 .should.equal 1

    test 'should know how many items of each type there are remaining', ->
      @board._get-current-item-count 1 .should.equal 2
      @board._clear-item-at {x: 0, y: 2}
      @board._get-current-item-count 1 .should.equal 1
      @board._clear-item-at {x: 0, y: 3}
      @board._get-current-item-count 1 .should.equal 0

    test "should remember what types there are, even after they've been taken", ->
      @board._clear-item-at {x: 2, y: 3}
      @board._clear-item-at {x: 3, y: 3}
      @board._get-current-item-count 3 .should.equal 0
      @board._get-current-item-count 4 .should.equal 0
      @board._types.should.eql [1, 2, 3, 4]

  suite 'calculating the winner', ->
    suite 'for an individual type', ->
      bill = \Bill
      ben = \Ben

      suite 'with only one item type', ->
        setup ->
          @board = new Board [
            [0, 0, 1],
            [0, 0, 1],
            [0, 0, 1]
          ]
          @board.add-bot bill, {x: 0, y: 0}
          @board.add-bot ben, {x: 0, y: 0}

        test 'when bill or ben can win', ->
          should.not.exist @board.get-winner!

        test 'when bill has already won', ->
          for i in [1 to 4]
            @board._award-point bill, 1
          @board.get-winner!.should.equal bill

        test "when bill can win or draw, but ben can't win", ->
          for i in [1 to 3]
            @board._award-point bill, 1
          should.not.exist @board.get-winner!

        test "when it's finished and it's a draw", ->
          board = new Board [[1, 0], [0, 0]]
          board.add-bot bill, {x: 0, y: 0}
          board.add-bot ben, {x: 0, y: 0}
          board._handle-takes [bill, ben]
          board.get-winner!.should.equal false

        test 'checks all items types (including ones which have all been removed from the board', ->
          board = new Board [[1, 0], [0, 0]]
          board.add-bot bill, {x: 0, y: 0}
          board.add-bot ben, {x: 0, y: 0}
          board._handle-takes [bill]
          board.get-winner!.should.equal bill

      suite 'with 3 item types', ->
        setup ->
          @board = new Board [
            [0, 0, 1],
            [0, 0, 2],
            [0, 0, 3]
          ]
          @board.add-bot bill, {x: 0, y: 0}
          @board.add-bot ben, {x: 0, y: 0}

        test 'when bill or ben can win', ->
          should.not.exist @board.get-winner!

        test 'when bill has already won', ->
          for i in [1 to 2]
            @board._award-point bill, 1 # bill has won type 1
            @board._award-point bill, 2 # bill has won type 2
          @board.get-winner!.should.equal bill

        test "when bill can win or draw, but ben can't win", ->
          for i in [1 to 2]
            @board._award-point bill, 1 # bill has won type 1
          @board._award-point bill, 2 # bill can win or draw type 2
          should.not.exist @board.get-winner!

  suite 'handling invalid situations', ->
    test 'should throw an exception when there are no items in the board', ->
      cells-without-items = [[0, 0], [0, 0]]
      (-> new Board cells-without-items).should.throw!

    test 'should throw an exception when there are more than 2 bots', ->
      board = new Board [[0, 0], [0, 1]]
      board.add-bot \a, {x: 0, y: 0}
      board.add-bot \b, {x: 0, y: 0}
      (-> board.add-bot \c, {x: 0, y: 0}).should.throw!

  test 'should have width and height the right way round', ->
    board = new Board [
      [0, 0, 0],
      [0, 0, 1]
    ]
    board.get-width().should.equal 2
    board.get-height().should.equal 3
