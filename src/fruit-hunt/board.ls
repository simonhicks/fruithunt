_ = require \underscore

exports.Board = class Board
  NORTH = @NORTH = \north
  EAST = @EAST = \east
  SOUTH = @SOUTH = \south
  WEST = @WEST = \west
  TAKE = @TAKE = \take
  PASS = @PASS = \pass

  (cells)->
    @_bots = {}
    @_clone-cells cells
    @_calculate-item-data!

  has-bot: (bot-id) ->
    @_bots.has-own-property bot-id

  get-board: ~>
    @_cells

  get-item-at: ({x, y}:position) ~>
    @_cells[x][y]

  get-position: (bot-id) ~>
    {x, y} = @_get-bot bot-id
    {x: x, y: y}

  get-opponent: (bot-id) ->
    @_bots[bot-id].opponent ?= @_calculate-opponent-for(bot-id)

  get-types: ->
    @_types

  get-total-item-count: (type) ->
    @_item-counts[type]

  _calculate-opponent-for: (bot-id) ->
    bot-ids = _.keys @_bots
    if bot-ids[0] is bot-id then bot-ids[1] else bot-ids[0]

  add-bot: (bot-id, position) ->
    if _.keys @_bots .length >= 2
      throw new Error 'Only 2 bots are allowed per game'
    @_bots[bot-id] = {}
    @_set-position bot-id, position

  get-direction = (dir) ->
    | dir == NORTH => [0, -1]
    | dir == EAST  => [1, 0]
    | dir == SOUTH => [0, 1]
    | dir == WEST  => [-1, 0]
    | dir == PASS  => [0, 0]

  move-bot: (bot-id, dir) ->
    {x, y} = @get-position bot-id
    [x, y] += get-direction dir
    [x, y] = @_apply-bounds {x: x, y: y}
    @_set-position(bot-id, {x: x, y: y})

  get-score: (bot-id, type) ~>
    @_get-bot(bot-id).{}scores[type] ? 0

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
      remaining = @_get-current-item-count type
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

  _calculate-item-data: ->
    item-data = @_get-cell-iterator!.filter(-> it).value!
    @_types = _.uniq item-data
    @_item-counts = _.count-by(item-data, -> it)

  _get-current-item-count: (type) ->
    @_get-cell-iterator!.filter (== type) .value!.length

  _clear-item-at: ({x, y}:position) ->
    @_cells[x][y] = 0

  _get-bot: (bot-id) ->
    @_bots[bot-id]

  _set-position: (bot-id, position) ->
    @_get-bot(bot-id) <<< position

  constrain = (min, max, n) ->
    | n >= max => max
    | n <= min => min
    | otherwise => n

  get-width: ->
    @_width ?= @_cells.length

  get-height: ->
    @_height ?= @_cells[0].length

  _apply-bounds: ({x, y}:position) ->
    max-x = @get-width! - 1
    max-y = @get-height! - 1
    [constrain(0, max-x, x), constrain(0, max-y, y)]

  _award-point: (bot-id, type, shared) ->
    scores =  @_get-bot(bot-id).{}scores
    old-score = scores[type] ? 0
    scores[type] = old-score + (if shared then 0.5 else 1)

  _handle-moves: (decisions) ->
    takes = []
    for bot-id, decision of decisions
      if decision is TAKE
        takes.push bot-id
      else
        @move-bot bot-id, decision
    takes

  # takes is a list of bot-ids (maximum 2) for the bots who have chosen 'take' as the move
  # for this turn
  _handle-takes: (takes) ->
    takes = _ takes .map ~> {bot-id: it, pos: @get-position it}
    if takes.length > 1 && takes[0].pos.x is takes[1].pos.x && takes[0].pos.y is takes[1].pos.y
      @_take-item takes[0].pos, takes[0].bot-id, takes[1].bot-id
    else
      for {bot-id, pos} in takes
        @_take-item pos, bot-id

  _take-item: (position, ...bot-ids) ->
    if (type = @get-item-at position)
      @_clear-item-at position
      for bot-id in bot-ids
        @_award-point bot-id, type, bot-ids.length > 1
