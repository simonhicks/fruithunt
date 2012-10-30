should = require \should

{FruitHunt} = require '../lib/fruit_hunt'

suite 'FruitHunt', ->
  suite 'newly created', ->
    board = [[0, 1], [0, 0]]

    setup ->
      @game = new FruitHunt board

    suite 'managing the board', ->
      test 'should clone the board it is given', ->
        @game.board.should.not.equal board
        @game.board.should.eql board

      test 'should know the item at each board location', ->
        @game.get-item-at 0, 0 .should.equal 0
        @game.get-item-at 0, 1 .should.equal 1

      test 'should be able to set the item at a board location', ->
        @game.get-item-at 0, 0 .should.equal 0
        @game.set-item-at 0, 0, 2
        @game.get-item-at 0, 0 .should.equal 2
        @game.set-item-at 0, 0, null
        @game.get-item-at 0, 0 .should.equal 0

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
      @game.get-position name .should.eql [1, 2]

    test 'should be able to move a bot east', ->
      @game.move-bot name, \east
      @game.get-position name .should.eql [2, 1]

    test 'should be able to move a bot south', ->
      @game.move-bot name, \south
      @game.get-position name .should.eql [1, 0]

    test 'should be able to move a bot west', ->
      @game.move-bot name, \west
      @game.get-position name .should.eql [0, 1]

  suite 'calculating the winner', ->
