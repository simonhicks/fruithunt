should = require \should
_ = require \underscore
fs = require \fs
child_process = require \child_process

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
      logPath: 'asdf.txt'
      code: 'function make_move() { }'

  suite 'on initialization,', ->

    suite 'when checking arguments', ->

      setup ->
        @create-instance = ~>
          new BotExecutor(@opts)

        @assert-mandatory-field = (field-name) ~>
          valid-instance = @create-instance()
          valid-instance[field-name].should.eql @opts[field-name]
          @opts[field-name] = null
          @create-instance.should.throw-error new RegExp(field-name)

      test 'should require a Board instance', ->
        @assert-mandatory-field('board')

      test 'should require a bot id', ->
        @assert-mandatory-field('botId')

      test 'should require a code string which defines the bot', ->
        @assert-mandatory-field('code')

      test 'should optionally accept a logfile path', ->
        @opts.log-path = null
        @create-instance.should.not.throw-error()

      test 'should validate that the board includes the given bot id', ->
        @opts.bot-id = 'not a valid bot id'
        @create-instance.should.throw-error(/botId/)

      test 'should validate the code argument', ->
        @opts.code = 'not valid code'
        (~> new BotExecutor @opts).should.throw-error(/Invalid code/)

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

    suite 'when exposing functions', ->
      setup ->
        @assert-nullary-function-in-sandbox = (fn-name, expected-result) ->
          @assert-api-string-result "return #fn-name();", expected-result

        @assert-api-string-result = (code-string, expected-result) ~>
          @opts.code = mm code-string
          bot-executor = new BotExecutor @opts
          bot-executor.make-move().should.eql expected-result

      test 'should expose the board via the get_board() global', ->
        @assert-nullary-function-in-sandbox \get_board, @opts.board.get-board()

      test "should expose this bot's x position via get_my_x()", ->
        board = @opts.board
        me = @opts.bot-id
        board.move-bot me, SOUTH
        @assert-nullary-function-in-sandbox \get_my_x, board.get-position(me).x

      test "should expose this bot's y position via get_my_y()", ->
        board = @opts.board
        me = @opts.bot-id
        board.move-bot me, SOUTH
        @assert-nullary-function-in-sandbox \get_my_y, board.get-position(me).y

      test "should expose the other bot's x position via get_opponent_x()", ->
        board = @opts.board
        other = @bots[1]
        other.should.not.eql @opts.bot-id
        board.move-bot other, SOUTH
        @assert-nullary-function-in-sandbox \get_opponent_x, board.get-position(other).x

      test "should expose the other bot's x position via get_opponent_y()", ->
        board = @opts.board
        other = @bots[1]
        other.should.not.eql @opts.bot-id
        board.move-bot other, SOUTH
        @assert-nullary-function-in-sandbox \get_opponent_y, board.get-position(other).y

      test 'should expose the has_item(field) global', ->
        @assert-api-string-result "return has_item(1)", true
        @assert-api-string-result "return has_item(0)", false

      test 'should expose the get_number_of_item_types() global', ->
        @assert-nullary-function-in-sandbox \get_number_of_item_types, @opts.board.get-types().length

      test 'should expose the get_my_item_count(type) global', ->
        for type in @opts.board.get-types()
          expected = @opts.board.get-score @opts.bot-id, type
          @assert-api-string-result "return get_my_item_count(#type);", expected

      test 'should expose the get_opponent_item_count(type) global', ->
        for type in @opts.board.get-types()
          expected = @opts.bot-id |> @opts.board.get-opponent |> @opts.board.get-score
          @assert-api-string-result "return get_opponent_item_count(#type);", expected

      test 'should expose the get_total_item_count(type) global', ->
        for type in @opts.board.get-types()
          expected = @opts.board.get-total-item-count type
          @assert-api-string-result "return get_total_item_count(#type);", expected

    suite 'providing trace functionality', ->
      setup ->
        @delete-dir-if-present = (directory) ->
          if fs.exists-sync directory
            child_process.exec "rm -rf #directory"

      test 'should expose the trace(string) global function', ->
        @assert-api-string-result "return typeof trace", 'function'

      test 'the trace function should write to the specified log file path if present', (done) ->
        log-dir = "log"
        @delete-dir-if-present(log-dir)
        @opts.log-path = "#log-dir/temp-test-log.txt"

        expected-string = 'the string has been written!'
        @opts.code = mm "trace('#expected-string');"
        bot-executor = new BotExecutor @opts

        bot-executor.make-move()
        # use a timeout here so we can avoid passing a callback into the trace function
        set-timeout ~>
          result = fs.read-file-sync @opts.log-path, 'utf-8'
          result.should.equal "#expected-string\n"
          @delete-dir-if-present(log-dir)
          done()
        , 15

      test 'the trace function should not raise an error if no path is given', (done) ->
        @opts.code = mm "trace('this wont go anywhere');"
        @opts.log-path = null
        bot-executor = new BotExecutor @opts
        bot-executor.make-move()
        set-timeout((~> done()), 15)

    test 'should throw an helpful error if a function throws an error', ->
      message = 'some error message'
      @opts.code = mm "throw new Error('#message');"
      bot-executor = new BotExecutor @opts
      try
        bot-executor.make-move()
        should.fail 'Expected an error'
      catch err
        err.message.should.match(new RegExp @opts.bot-id)
        err.message.should.match(new RegExp message)

    test 'should track changes in global state', ->
      # initialize global variable x if it doesn't exist, then increment it
      @opts.code = mm "return ((typeof x == 'undefined' || x == null) && (x = 0)) || (x += 1);"
      bot-executor = new BotExecutor @opts
      bot-executor.make-move()
      bot-executor.make-move().should.equal 2
