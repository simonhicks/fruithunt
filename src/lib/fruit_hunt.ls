global <<< require \prelude-ls

exports.FruitHunt = class FruitHunt
  (board, @bots = {})->
    @board = []
    for col in board
      @board.push [item for item in col]

  get-item-at: (x, y) ->
    @board[x][y]

  set-item-at: (x, y, item) ->
    @board[x][y] = item ? 0

  add-bot: (name, [x, y], bot) ->
    bot <<< {x: x, y: y}
    @bots[name] = bot

  get-bot: (name) ->
    @bots[name]

  get-position: (name) ->
    {x, y} = @get-bot name
    [x, y]

  get-direction = (dir) ->
    | dir == \north => [0, 1]
    | dir == \east  => [1, 0]
    | dir == \south => [0, -1]
    | dir == \west  => [-1, 0]

  move-bot: (name, dir) ->
    [x, y] = @get-position name
    [x, y] += get-direction dir
    @get-bot(name) <<< {x: x, y: y}
