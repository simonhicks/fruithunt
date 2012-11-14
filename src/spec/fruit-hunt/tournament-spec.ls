should = require \should
_ = require \underscore

{Tournament,Game} = require '../../fruit-hunt'

suite 'Tournament', ->
  setup ->
    function make_move
      if get_board()[get_my_x()][get_my_y()]
        TAKE
      else
        [NORTH, EAST, SOUTH, WEST][Math.random() |> (* 4) |> Math.floor]
    code = make_move.to-string()

    @bots =
      * new Bot id: 'bot-1', code: code
      * new Bot id: 'bot-2', code: code
      * new Bot id: 'bot-3', code: code
      * new Bot id: 'bot-4', code: code

    @min-opts =
      bots: @bots

  suite 'when newly created', ->
    test 'requires a collection of bots'
    test 'accepts a number of games per round'
    test "shouldn't fail if number of games isn't passed"

  suite 'when playing', ->
    # use stubbed version of Game for this
    test 'makes each bot play each other bot N times'
    test 'ranks the bots in the order of the number of games they won'

