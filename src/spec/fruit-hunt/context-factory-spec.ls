should = require \should
_ = require \underscore
fs = require \fs
child_process = require \child_process
{Script} = require \vm

{Bot} = require '../../fruit-hunt/bot'
{ContextFactory} = require '../../fruit-hunt/context-factory'
{BoardFactory, Board} = require '../../fruit-hunt'
{NORTH,EAST,SOUTH,WEST,TAKE,PASS} = Board

# FIXME add ContextFactory.createContext({bot, board})

suite 'ContextFactory', ->
  setup ->
    @bot-ids = <[bill ben]>
    @the-bot = new Bot id: @bot-ids[0], code: 'function make_move() { }', log-path: 'the-log.txt'
    board = BoardFactory.create-board(bot-ids: @bot-ids)
    @opts =
      board: board
      bot: @the-bot

  suite 'on initialization,', ->

    suite 'when checking arguments', ->

      setup ->
        @create-instance = ~>
          new ContextFactory(@opts)

      test 'should require a Board instance', ->
        valid-instance = @create-instance()
        valid-instance.board.should.eql @opts.board
        @opts.board = null
        @create-instance.should.throw-error /\bboard\b/

      test 'should require a bot', ->
        valid-instance = @create-instance()
        valid-instance.bot-id.should.eql @opts.bot.id
        @opts.bot = null
        @create-instance.should.throw-error /\bbot\b/

      test "should extract the bot's log-path if there is one", ->
        valid-instance = @create-instance()
        valid-instance.log-path.should.equal @opts.bot.log-path
        @opts.bot.log-path = null
        @create-instance.should.not.throw-error()

      test 'should validate that the board includes the given bot id', ->
        @opts.bot.id = 'not a valid bot'
        @create-instance.should.throw-error(/bot id/)

  suite 'creating a sandbox', ->
    suite 'when exposing constants', ->
      setup ->
        @assert-constant-in-sandbox = (name, value) ->
          context-factory = new ContextFactory @opts
          context = context-factory.get-context()
          new Script("#name;").run-in-context(context).should.eql value

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
          @assert-api-string-result "#fn-name();", expected-result

        @assert-api-string-result = (code-string, expected-result) ~>
          context-factory = new ContextFactory @opts
          context = context-factory.get-context()
          new Script(code-string).run-in-context context .should.eql expected-result

      test 'should expose the board via the get_board() global', ->
        @assert-nullary-function-in-sandbox \get_board, @opts.board.get-board()

      test "should expose this bot's x position via get_my_x()", ->
        board = @opts.board
        #me = @opts.bot-id
        me = @opts.bot.id
        board.move-bot me, SOUTH
        @assert-nullary-function-in-sandbox \get_my_x, board.get-position(me).x

      test "should expose this bot's y position via get_my_y()", ->
        board = @opts.board
        #me = @opts.bot-id
        me = @opts.bot.id
        board.move-bot me, SOUTH
        @assert-nullary-function-in-sandbox \get_my_y, board.get-position(me).y

      test "should expose the other bot's x position via get_opponent_x()", ->
        board = @opts.board
        other = @bot-ids[1]
        #other.should.not.eql @opts.bot-id
        other.should.not.eql @opts.bot.id
        board.move-bot other, SOUTH
        @assert-nullary-function-in-sandbox \get_opponent_x, board.get-position(other).x

      test "should expose the other bot's y position via get_opponent_y()", ->
        board = @opts.board
        other = @bot-ids[1]
        #other.should.not.eql @opts.bot-id
        other.should.not.eql @opts.bot.id
        board.move-bot other, SOUTH
        @assert-nullary-function-in-sandbox \get_opponent_y, board.get-position(other).y

      test 'should expose the has_item(field) global', ->
        @assert-api-string-result "has_item(1)", true
        @assert-api-string-result "has_item(0)", false

      test 'should expose the get_number_of_item_types() global', ->
        @assert-nullary-function-in-sandbox \get_number_of_item_types, @opts.board.get-types().length

      test 'should expose the get_my_item_count(type) global', ->
        for type in @opts.board.get-types()
          #expected = @opts.board.get-score @opts.bot-id, type
          expected = @opts.board.get-score @opts.bot.id, type
          @assert-api-string-result "get_my_item_count(#type);", expected

      test 'should expose the get_opponent_item_count(type) global', ->
        for type in @opts.board.get-types()
          #expected = @opts.bot-id |> @opts.board.get-opponent |> @opts.board.get-score
          expected = @opts.bot.id |> @opts.board.get-opponent |> @opts.board.get-score
          @assert-api-string-result "get_opponent_item_count(#type);", expected

      test 'should expose the get_total_item_count(type) global', ->
        for type in @opts.board.get-types()
          expected = @opts.board.get-total-item-count type
          @assert-api-string-result "get_total_item_count(#type);", expected

      suite 'providing trace functionality', ->
        setup ->
          @delete-dir-if-present = (directory) ->
            if fs.exists-sync directory
              child_process.exec "rm -rf #directory"

        test 'should expose the trace(string) global function', ->
          @assert-api-string-result "typeof trace", 'function'

        test 'the trace function should write to the specified log file path if present', (done) ->
          log-dir = "log"
          @delete-dir-if-present(log-dir)
          @opts.bot.log-path = "#log-dir/temp-test-log.txt"

          expected-string = 'the string has been written!'
          script = new Script "trace('#expected-string');"
          context-factory = new ContextFactory @opts

          script.run-in-context context-factory.get-context()
          # use a timeout here so we can avoid passing a callback into the trace function
          set-timeout ~>
            result = fs.read-file-sync @opts.bot.log-path, 'utf-8'
            result.should.equal "#expected-string\n"
            @delete-dir-if-present(log-dir)
            done()
          , 15

        test 'the trace function should not raise an error if no path is given', (done) ->
          script = new Script "trace('this wont go anywhere');"
          @opts.bot.log-path = null
          context-factory = new ContextFactory @opts
          script.run-in-context(context-factory.get-context())
          set-timeout((~> done()), 15)
