{Board} = require './board'

exports.BoardFactory = class BoardFactory
  @create-board = ({min-size, max-size}:opts = {}) ->
    new this min-size, max-size .get-board!

  (@min-size=5,@max-size=15) ->
    @cells = []

  get-cells: ->
    if @cells.length == 0
      @initialize-cells!
      @add-items!
    @cells

  get-board: ->
    new Board @get-cells!

  initialize-cells: ->
    for row in [0 til @get-height!]
      @cells.push [0 for cell in [0 til @get-width!]]

  add-items: ->
    for type in @get-types!
      for i in [0 til 2 * type + 1]
        @place-item type

  get-types: ->
    unless @types?
      var num
      do
        num := @random! * 3 + 3
      until num * num < @get-height! * @get-width!
      @types = [1 to num]
    @types

  place-item: (type) ->
    do
      x = Math.min Math.floor(@random! * @get-width!), @get-width!
      y = Math.min Math.floor(@random! * @get-height!), @get-height!
    until @cells[y][x] == 0
    @cells[y][x] = type

  get-width: ->
    unless @width?
      @width = @random-dimension!
    @width

  get-height: ->
    unless @height?
      @height = @random-dimension!
    @height

  random-dimension: ->
    range = @max-size - @min-size
    min = @min-size
    @random! |> (* range) |> (+ min) |> Math.floor

  random: Math.random # alias so we can test properly
