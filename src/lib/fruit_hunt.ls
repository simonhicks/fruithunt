_ = require \underscore

exports.FruitHunt = class FruitHunt
  (board, @_bots = {})->
    @_clone-board board
    @_types = @get-item-types!

  _clone-board: (board) ->
    find-item = (coll) -> _.find(coll, (> 0))
    if (board |> _.flatten |> find-item)
      @_board = []
      for row in board
        @_board.push [item for item in row]
    else
      throw new Error "Illegal board: There are no items!"

  get-item-iterator: ->
    _ @_board .chain!.flatten!.filter -> it

  get-item-types: ->
    @get-item-iterator!.uniq!.value!

  get-item-counts: ->
    @get-item-iterator!.count-by(-> it).value!

  get-item-count: (type) ->
    @get-item-counts![type] ? 0

  get-item-at: ([x, y]:position) ~>
    @_board[y][x]

  set-item-at: ([x, y]:position, item) ->
    @_board[y][x] = item ? 0

  add-bot: (name, position, bot) ->
    @_bots[name] = bot ? {}
    @set-position name, position

  get-bot: (name) ->
    @_bots[name]

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
    max-x = @_board.length - 1
    max-y = @_board[0].length - 1
    [constrain(0, max-x, x), constrain(0, max-y, y)]

  move-bot: (name, dir) ->
    [x, y] = @get-position name
    [x, y] += get-direction dir
    position = @apply-bounds [x, y]
    @set-position(name, position)

  get-score: (name, type) ~>
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

  # given a particular bot's lead in a contest and the remaining number of points available, this returns a best and worst case scenario for that bot.
  # 1 means a victory, 0 means a draw, -1 means a loss
  #
  # @param lead       int The specified bot's lead
  # @param remaining  int The number of points remaining in this contest
  #
  # @returns [best, worst]
  best-worst = (lead, remaining) ->
    | (lead - remaining) > 0 => [1, 1]
    | (lead + remaining) < 0 => [-1, -1]
    | (lead - remaining) == 0 => [1, 0]
    | (lead + remaining) == 0 => [0, -1]
    | otherwise => [1, -1]

  get-winner: ->
    [bot0, bot1] = _.keys @_bots
    [best, worst] = [0, 0]
    for type in @get-item-types!
      bot0-lead = @get-score(bot0, type) - @get-score(bot1, type)
      remaining = @get-item-count type
      [best, worst] += best-worst(bot0-lead, remaining)
    if worst > 0
      bot0
    else if best < 0
      bot1
    else if best == worst == 0
      false
