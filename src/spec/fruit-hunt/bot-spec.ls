should = require \should
_ = require \underscore
vm = require \vm
{Script} = vm

{Bot} = require '../../fruit-hunt/bot'

suite 'Bot', ->
  setup ->
    @min-opts =
      id: 'bob'
      code: '''
      function make_move() {
        return MAKE_MOVE;
      }

      function new_game() {
        return NEW_GAME;
      }
      '''
    @create-instance = ~> new Bot @min-opts

  suite 'on initialization', ->
    test 'should require an id', ->
      @create-instance.should.not.throw-error
      @min-opts.id = null
      @create-instance.should.throw-error(/id/)

    test 'should require a code string', ->
      @create-instance.should.not.throw-error
      @min-opts.code = null
      @create-instance.should.throw-error(/code/)

    test 'should ensure the code string is valid', ->
      @create-instance.should.not.throw-error
      @min-opts.code = '''
      function make_move() {
        This is not valid;
      }
      '''
      @create-instance.should.throw-error /SyntaxError/
      @create-instance.should.throw-error /code/
      @create-instance.should.throw-error new RegExp @min-opts.id

    test 'should set the log path if one is assigned and expose it via #get-log-path', ->
      @min-opts.log-path = 'path/to/bot.log'
      @create-instance().get-log-path().should.equal @min-opts.log-path

    test 'should expose a log-path setter', ->
      @min-opts.log-path = 'path/to/bot.log'
      bot = @create-instance()
      bot.get-log-path().should.equal @min-opts.log-path
      bot.set-log-path(expected = 'expected')
      bot.get-log-path().should.equal expected

    test "shouldn't raise an error when log-path isn't assigned", ->
      @min-opts.log-path = null
      @create-instance.should.not.throw-error

  suite 'setting the @_context', ->
    test "should convert an object passed to set-new-context into a node vm context object", ->
      bot = @create-instance()
      expected = 'expected'
      bot.set-new-context({global-var: expected})
      bot.get-context().should.be.an.instanceof vm.createContext({}).constructor
      bot.get-context().global-var.should.equal expected

    test "should add it's own definitions to the newly created context", ->
      bot = @create-instance()
      bot.set-new-context({})
      # need to use .constructor.name because these functions are created in a sandbox,
      # so they use different instances of all globals
      bot._context.make_move.constructor.name.should.eql 'Function'
      bot._context.new_game.constructor.name.should.eql 'Function'

    test 'should reset the context when #reset-context was called', ->
      bot = @create-instance()
      bot.set-new-context({})
      bot.get-context().should.be.an.instanceof vm.createContext({}).constructor
      bot.reset-context()
      (bot.get-context() == null).should.equal true

  suite 'exposing bot functionality:', ->
    test 'should throw a helpful error message when a function throws an error', ->
      error-message = 'expected error'
      bot = new Bot id: 'bob', code: """
        function make_move() {
          throw new Error("#error-message");
        }
        """
      bot.set-new-context EXPECTED: 'expected'
      bot.make-move.should.throw-error new RegExp error-message
      bot.make-move.should.throw-error new RegExp bot.id

    suite 'make-move()', ->
      test "should execute the bot's make_move() function in the current context", ->
        expected = 'expected result'
        bot = new Bot id: 'bob', code: """
          function make_move() {
            return EXPECTED;
          }
        """
        bot.set-new-context EXPECTED: expected
        bot.make-move().should.equal expected

      test "should throw an error when make_move() isn't defined", ->
        bot = new Bot id: 'bob', code: """
          function new_game() {
            return EXPECTED;
          }
        """
        bot.set-new-context EXPECTED: 'expected'
        bot.make-move.should.throw-error /make_move()/

      test "should throw an error when the context isn't set", ->
        bot = new Bot id: 'bob', code: """
          function make_move() {
            return 1;
          }
        """
        bot.make-move.should.throw-error /execution context/i

    suite 'new-game()', ->
      test "should execute the bot's new_game() function in the curent context", ->
        expected = 'expected result'
        bot = new Bot id: 'bob', code: """
          function new_game() {
            return EXPECTED;
          }
        """
        bot.set-new-context EXPECTED: expected
        bot.new-game().should.equal expected

      test "shouldn't throw an error when new_game() isn't defined", ->
        bot = new Bot id: 'bob', code: """
          function make_move() {
            return 1;
          }
        """
        bot.set-new-context {}
        bot.new-game.should.not.throw-error()

      test "should throw an error when the context isn't set", ->
        bot = new Bot id: 'bob', code: """
          function new_game() {
            return 1;
          }
        """
        bot.new-game.should.throw-error /execution context/i
