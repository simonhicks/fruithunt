vm = require \vm
Script = vm.Script
fs = require \fs
path = require \path

{Board} = require './board'

# FIXME Change this, so it's a ContextFactory, with a ContextFactory.createContext({bot, board}) method

exports.ContextFactory = class ContextFactory

  ({@board,{id: @bot-id ,@log-path}:bot={}}) ->
    @_validate()
    @_prepare-log-path()

  _validate: ->
    @_validate-mandatory-args()
    @_validate-bot-id()

  _validate-bot-id: ->
    unless @board.has-bot @botId
      throw new Error "Invalid bot id '#{@botId}'"

  _prepare-log-path: ->
    p = path.dirname @log-path
    unless fs.exists-sync p
      fs.mkdir-sync p

  _validate-mandatory-args: ->
    unless @board?
      @_missing-arg \board
    unless @bot-id?
      @_missing-arg \bot

  _missing-arg: (field) ->
    throw new Error "Missing mandatory arg #field"

  get-context: ->
    @_context ?= vm.create-context(
      # Constants
      WIDTH: @board.get-width()
      HEIGHT: @board.get-height()
      NORTH: Board.NORTH
      EAST: Board.EAST
      SOUTH: Board.SOUTH
      WEST: Board.WEST
      TAKE: Board.TAKE
      PASS: Board.PASS

      # Functions
      get_board: @board.get-board
      get_my_x: ~>
        @board.get-position(@bot-id).x
      get_my_y: ~>
        @board.get-position(@bot-id).y
      get_opponent_x: ~>
        @board.get-position(@_get-opponent-id()).x
      get_opponent_y: ~>
        @board.get-position(@_get-opponent-id()).y
      has_item: (field) ->
        field > 0
      get_number_of_item_types: ~>
        @board.get-types().length
      get_my_item_count: (type) ~>
        @board.get-score @bot-id, type
      get_opponent_item_count: (type) ~>
        @board.get-score @_get-opponent-id(), type
      get_total_item_count: (type) ~>
        @board.get-total-item-count type
      trace: (string) ~>
        @_trace string
    )

  _get-opponent-id: ->
    @_opponent ?= @board.get-opponent @bot-id

  _trace: (string) ->
    if @log-path?
      fs.write-file-sync @log-path, "#string\n"
