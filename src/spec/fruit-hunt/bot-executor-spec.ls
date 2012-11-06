should = require \should
_ = require \underscore

{BotExecutor} = require '../../fruit-hunt/bot-executor'
{BoardFactory, Board} = require '../../fruit-hunt'
{NORTH,EAST,SOUTH,WEST,TAKE,PASS} = Board

suite 'BotExecutor', ->
  setup ->
    @bots = <[bill ben]>
    board = BoardFactory.create-board(bot-ids: @bots)
    @opts =
      board: board
      botId: @bots[0]
      logPath: 'path/to/log.file'
      code: 'function make_move() { }'

  suite 'on initialization,', ->
    suite 'when checking arguments', ->
      setup ->
        @create-instance = ~>
          new BotExecutor(@opts)

      mandatory-field-test = (field-name) ~>
        ->
          valid-instance = @create-instance()
          valid-instance[field-name].should.eql @opts[field-name]
          @opts[field-name] = null
          @create-instance.should.throw-error new RegExp(field-name)

      test 'should require a Board instance', mandatory-field-test('board')
      test 'should require a bot id', mandatory-field-test('botId')
      test 'should require a code string which defines the bot', mandatory-field-test('code')

      test 'should optionally accept a logfile path', ->
        @opts.log-path = null
        @create-instance.should.not.throw-error()

      test 'should validate that the board includes the given bot id', ->
        @opts.bot-id = 'not a valid bot id'
        @create-instance.should.throw-error(/botId/)

      test 'should throw an error when code is invalid javscript'

  suite "when executing a bot's functions", ->
    mm = (code) -> "function make_move() { #{code} }"

    test "should not throw an error if new_game() isn't defined", ->
      @opts.code = "function make_move() {}"
      create-instance = ~> new BotExecutor @opts
      create-instance.should.not.throw-error()
      (-> create-instance().new-game()).should.not.throw-error()

    test "should throw an error if make_move() isn't defined", ->
      @opts.code = "function new_game() {}"
      create-instance = ~> new BotExecutor @opts
      create-instance.should.throw-error()

    suite 'when exposing constants', ->
      setup ->
        @assert-constant-in-sandbox = (name, value) ->
          @opts.code = mm("return #name;")
          bot-executor = new BotExecutor @opts
          bot-executor.make-move().should.equal value

      test 'should expose the constant WIDTH as a global variable', ->
        @assert-constant-in-sandbox "WIDTH", @opts.board.get-width()

      test 'should expose the constant HEIGHT as a global variable', ->
        @assert-constant-in-sandbox 'HEIGHT', @opts.board.get-height()

      test 'should expose constants for all the move options', ->
        @assert-constant-in-sandbox 'NORTH', NORTH
        @assert-constant-in-sandbox 'EAST', EAST
        @assert-constant-in-sandbox 'SOUTH', SOUTH
        @assert-constant-in-sandbox 'WEST', WEST
        @assert-constant-in-sandbox 'TAKE', TAKE
        @assert-constant-in-sandbox 'PASS', PASS

    test 'should expose the board via the get_board() global'
    test "should expose this bot's position via get_my_x() and get_my_y() global"
    test "should expose the other bot's get_opponent_x() and get_opponent_y() globals"

    test 'should expose the has_item(field) global'
    test 'should expose the get_number_of_item_types() global'
    test 'should expose the get_my_item_count(type) global'
    test 'should expose the get_opponent_item_count(type) global'
    test 'should expose the get_total_item_count(type) global'

  suite 'providing trace functionality', ->
    test 'should expose the trace(string) global function'
    test 'the trace function should write to the specified log file path if present'
    test 'the trace function should write to console.log if no log file path is given'

  suite 'tracking changes in global state', ->
    # should keep track of changes bots make to global state
