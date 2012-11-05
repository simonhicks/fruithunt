_ = require \underscore

# TODO rename this to Board (and change other names so everything is consistent

# FIXME change references to bot names to a more sensible variable name
exports.Board = class Board
  (cells)->
    @_bots = {}
    @_clone-cells cells
    @_types = @_calculate-item-types!

  get-item-at: ([x, y]:position) ~>
    @_cells[y][x]

  get-position: (name) ~>
    {x, y} = @_get-bot name
    [x, y]

  add-bot: (name, position, bot) ->
    if _.keys @_bots .length >= 2
      throw new Error 'Only 2 bots are allowed per game'
    @_bots[name] = bot ? {}
    @_set-position name, position

  get-direction = (dir) ->
    | dir == \north => [0, -1]
    | dir == \east  => [1, 0]
    | dir == \south => [0, 1]
    | dir == \west  => [-1, 0]

  move-bot: (name, dir) ->
    [x, y] = @get-position name
    [x, y] += get-direction dir
    position = @_apply-bounds [x, y]
    @_set-position(name, position)

  get-score: (name, type) ~>
    @_get-bot(name).{}scores[type] ? 0

  handle-turn: (decisions) ->
    decisions |> @_handle-moves |> @_handle-takes

  # for a given lead, this returns the best and worst case scenario (as per best-worst below)
  final-result = (lead) ->
    | lead > 0 => [1, 1]
    | lead == 0 => [0, 0]
    | lead < 0 => [-1, -1]

  # given a particular bot's lead in a contest and the remaining number of points available, this
  # returns a best and worst case scenario for that bot. 1 means a victory, 0 means a draw, -1 means a
  # loss
  #
  # @param lead       int The specified bot's lead
  # @param remaining  int The number of points remaining in this contest
  #
  # @returns [best, worst]
  best-worst = (lead, remaining) ->
    | remaining == 0 => final-result(lead)
    | (lead - remaining) > 0 => [1, 1]
    | (lead + remaining) < 0 => [-1, -1]
    | (lead - remaining) == 0 => [1, 0]
    | (lead + remaining) == 0 => [0, -1]
    | otherwise => [1, -1]

  get-winner: ->
    [bot0, bot1] = _.keys @_bots
    [best, worst] = [0, 0]

    for type in @_types
      bot0-lead = @get-score(bot0, type) - @get-score(bot1, type)
      remaining = @_get-item-count type
      [best, worst] += best-worst(bot0-lead, remaining)

    if worst > 0
      bot0
    else if best < 0
      bot1
    else if best == worst == 0
      false

  _clone-cells: (cells) ->
    find-item = (coll) -> _.find(coll, (> 0))
    if (cells |> _.flatten |> find-item)
      @_cells = []
      for row in cells
        @_cells.push [item for item in row]
    else
      throw new Error "Illegal board: There are no items!"

  _get-cell-iterator: ->
    _ @_cells .chain!.flatten!

  _calculate-item-types: ->
    @_get-cell-iterator!.filter(-> it).uniq!.value!

  _get-item-count: (type) ->
    @_get-cell-iterator!.filter (== type) .value!.length

  _clear-item-at: ([x, y]:position) ->
    @_cells[y][x] = 0

  _get-bot: (name) ->
    @_bots[name]

  _set-position: (name, [x, y]:position) ->
    @_get-bot(name) <<< {x: x, y: y}

  constrain = (min, max, n) ->
    | n >= max => max
    | n <= min => min
    | otherwise => n

  get-width: ->
    @_width ?= @_cells.length

  get-height: ->
    @_height ?= @_cells[0].length

  _apply-bounds: ([x, y]) ->
    max-x = @get-width! - 1
    max-y = @get-height! - 1
    [constrain(0, max-x, x), constrain(0, max-y, y)]

  _award-point: (name, type, shared) ->
    scores =  @_get-bot(name).{}scores
    old-score = scores[type] ? 0
    scores[type] = old-score + (if shared then 0.5 else 1)

  _handle-moves: (decisions) ->
    takes = []
    for name, decision of decisions
      if decision is \take
        takes.push name
      else
        @move-bot name, decision
    takes

  # takes is a list of bot-ids for the bots who have chosed 'take' as the move
  # for this turn
  _handle-takes: (takes) ->
    for position, names of _ takes .group-by @get-position
      position = position.split ','
      shared = names.length > 1
      if (type = @get-item-at(position))
        @_clear-item-at position
        for name in names
          @_award-point name, type, shared
