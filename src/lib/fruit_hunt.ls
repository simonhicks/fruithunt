_ = require \underscore

exports.FruitHunt = class FruitHunt
  (board, @bots = {})->
    @board = []
    for row in board
      @board.push [item for item in row]

  get-item-at: ([x, y]) ~>
    @board[y][x]

  set-item-at: ([x, y], item) ->
    @board[y][x] = item ? 0

  add-bot: (name, position, bot) ->
    @bots[name] = bot
    @set-position name, position

  get-bot: (name) ->
    @bots[name]

  get-position: (name) ~>
    {x, y} = @get-bot name
    [x, y]

  set-position: (name, [x, y]:position) ->
    @get-bot(name) <<< {x: x, y: y}

  get-direction = (dir) ->
    | dir == \north => [0, -1]
    | dir == \east  => [1, 0]
    | dir == \south => [0, 1]
    | dir == \west  => [-1, 0]

  constrain = (min, max, n) ->
    | n >= max => max
    | n <= min => min
    | otherwise => n

  apply-bounds: ([x, y]) ->
    max-x = @board.length - 1
    max-y = @board[0].length - 1
    [constrain(0, max-x, x), constrain(0, max-y, y)]

  move-bot: (name, dir) ->
    [x, y] = @get-position name
    [x, y] += get-direction dir
    position = @apply-bounds [x, y]
    @set-position(name, position)

  get-score: (name, type) ->
    @get-bot(name).{}scores[type] ? 0

  award-point: (name, type, shared) ->
    scores =  @get-bot(name).{}scores
    old-score = scores[type] ? 0
    scores[type] = old-score + (if shared then 0.5 else 1)

  handle-turn: (decisions) ->
    decisions |> @handle-moves |> @handle-takes

  handle-moves: (decisions) ->
    takes = []
    for name, decision of decisions
      if decision is \take
        takes.push name
      else
        @move-bot name, decision
    takes

  handle-takes: (takes) ->
    for position, names of _ takes .group-by @get-position
      position = position.split ','
      shared = names.length > 1
      if (type = @get-item-at(position))
        @set-item-at position, 0
        for name in names
          @award-point name, type, shared
