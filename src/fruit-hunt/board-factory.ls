{Board} = require './board'

exports.BoardFactory = class BoardFactory
  @create-board = (options) ->
    new this(options).get-board()

  ({@min-size=5,@max-size=15,@bot-ids=[]}={}) ->
    if @bot-ids.length isnt 2
      throw new Error "Missing mandatory arg bot-ids. Please supply 2 bot-ids."
    @cells = []

  get-cells: ->
    if @cells.length == 0
      @initialize-cells()
      @add-items()
    @cells

  get-board: ->
    board = new Board @get-cells()
    for bot-id in @bot-ids
      board.add-bot bot-id, @get-bot-position()
    board

  get-bot-position: ->
    @bot-position ?= @get-empty-position()

  get-empty-position: ->
    i = 0
    do
      x = @random-between(0, @get-width())
      y = @random-between(0, @get-height())
      if i > 1000000
        throw new Error "Something went wrong creating a board. Couldn't find an empty space"
      i += 1
    until @get-cells()[y][x] is 0
    [x, y]

  initialize-cells: ->
    for row from 0 til @get-height()
      @cells.push [0 for cell in [0 til @get-width()]]

  add-items: ->
    for type in @get-types()
      n = 2 * (type - 1) + 1
      for i from 0 til n
        @place-item type

  get-types: ->
    unless @types?
      var num
      i = 0
      do
        num := @random() * 3 + 3
        i += 1
        if i > 1000000
          throw new Error "Something went wrong selecting a number of types. This probably means the board is too small"
      until num * num < @get-height() * @get-width()
      @types = [1 to num]
    @types

  place-item: (type) ->
    [x, y] = @get-empty-position()
    @cells[y][x] = type

  get-width: ->
    unless @width?
      @width = @random-dimension()
    @width

  get-height: ->
    unless @height?
      @height = @random-dimension()
    @height

  random-dimension: ->
    @random-between @min-size, @max-size

  random-between: (min, max) ->
    range = max - min
    @random() |> (* range) |> (+ min) |> Math.floor

  random: Math.random # alias so we can test properly
