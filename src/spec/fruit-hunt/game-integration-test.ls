should = require \should
_ = require \underscore

{BoardFactory,Game,Board,BotExecutor} = require '../../fruit-hunt'

suite 'Game integration test', ->
  # set up a small board so the game doesn't take too long!
  board-options = max-size: 5 min-size: 5

  # set up a bot that always passes.
  pass-bot =
    id: 'Passqual'
    code: 'function make_move(){ return PASS; }'

  # set up a bot that methodically walks from top left to bottom right until every square has been covered
  methodical-bot =
    id: 'Slow and steady'
    log-path: 'test.log'
    code: '''
    function report_board() {
      trace("BOARD: " + JSON.stringify(get_board()));
    }

    function report_position() {
      trace("POSITION: [" + get_my_x() + ", " + get_my_y() + "]");
    }

    function report_turn() {
      trace("------ TURN " + turn + " --------");
    }

    function report_move(move) {
      trace("DECISION: " + move);
    }

    function new_game() {
      turn = 0;
      reached_x0 = false;
      reached_y0 = false;
      direction = EAST;
      report_turn();
      report_board();
      report_position();
    }

    function change_direction() {
      if (direction === EAST)
        direction = WEST;
      else
        direction = EAST;
    }

    function im_on_an_item() {
      return get_board()[get_my_x()][get_my_y()] > 0;
    }

    function reached_end_of_row() {
      return (direction === EAST && get_my_x() === WIDTH - 1) || (direction === WEST && get_my_x() === 0);
    }

    function make_move() {
      turn++;
      var this_move;

      if (!reached_x0 && get_my_x() == 0)
        reached_x0 = true;

      if (!reached_y0 && get_my_y() == 0)
        reached_y0 = true;

      if (!reached_x0) {
        this_move =  WEST;
      } else if (!reached_y0) {
        this_move =  NORTH;
      } else if (im_on_an_item()) {
        this_move =  TAKE;
      } else if (reached_end_of_row()) {
        change_direction();
        this_move =  SOUTH;
      } else {
        this_move =  direction;
      }

      report_turn();
      report_position();
      report_move(this_move);
      return this_move;
    }
    '''

  #game = new Game pass-bot, methodical-bot, board-options
  game.play()
  game.get-winner().should.equal methodical-bot.id
