should = require \should
_ = require \underscore

Game = require '../../fruit-hunt/game'

suite 'Game', ->
  # is initialized with an object mapping bot id's to function body strings
  # contains a randomly generated board instance
  # creates an execution context for each bot function
  # should optionally include a log-directory
