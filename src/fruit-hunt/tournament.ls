_ = require \underscore
{Game,Bot} = require '../fruit-hunt'

exports.Tournament = class Tournament
  @DEFAULT_ROUNDS = 10

  @run = (opts) ->
    instance = new this(opts)
    instance.play()
    instance.get-results()

  ({@bots,@rounds,@board-options}) ->
    @_points = {}
    @_validate-bots()
    @_validate-rounds()

  _validate-bots: ->
    if not @bots?
      @_missing-arg \bots
    else if @bots.length < 2
      @_invalid-arg 'bots', 'must contain at least 2 bots'
    else if ! _.all(@bots, -> it.constructor == Bot)
      @_invalid-arg 'bots', 'should only contain instances of Bot'

  _validate-rounds: ->
    @rounds ?= @@DEFAULT_ROUNDS

  get-bots: -> @bots

  _missing-arg: (field) ->
    throw new Error "Missing mandatory arg #field"

  _invalid-arg: (field, msg) ->
    throw new Error "Invalid arg #field. #field #msg."

  _play-match: (bot1, bot2) ~>
    Game.play(bot1, bot2, @board-options) |> @_award-point

  _award-point: (winner) ~>
    @_points[winner] ?= 0
    @_points[winner]++

  _play-round: ~>
    [@_play-match(bot1, bot2) for bot1, i1 in @bots for bot2, i2 in @bots when i1 < i2]

  play: ->
    _.times @rounds, @_play-round

  get-results: ->
    _.sort-by @get-bots, ({id}) -> @_points[id] .reverse
