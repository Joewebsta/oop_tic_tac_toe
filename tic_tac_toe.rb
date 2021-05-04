# frozen_string_literal: true

class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # cols
                  [[1, 5, 9], [3, 5, 7]]              # diagonals

  def initialize
    @squares = {}
    reset
  end

  def []=(num, marker)
    @squares[num].marker = marker
  end

  def unmarked_keys
    @squares.keys.select { |key| @squares[key].unmarked? }
  end

  def unmarked_square_5?
    @squares[5].unmarked?
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      return squares.first.marker if three_identical_markers?(squares)
    end
    nil
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  def draw
    puts '     |     |'
    puts "  #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}"
    puts '     |     |'
    puts '-----+-----+-----'
    puts '     |     |'
    puts "  #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}"
    puts '     |     |'
    puts '-----+-----+-----'
    puts '     |     |'
    puts "  #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}"
    puts '     |     |'
  end

  def find_at_risk_square(marker)
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      markers = squares.map(&:marker)

      next unless markers.count(marker) == 2 && squares.one?(&:unmarked?)

      third_square = squares.select(&:unmarked?).first
      return @squares.key(third_square)
    end

    nil
  end

  private

  def three_identical_markers?(squares)
    markers = squares.select(&:marked?).map(&:marker)
    return false if markers.size != 3

    markers.min == markers.max
  end
end

class Square
  INITIAL_MARKER = ' '

  attr_accessor :marker

  def initialize(marker = INITIAL_MARKER)
    @marker = marker
  end

  def to_s
    @marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end

  def marked?
    marker != INITIAL_MARKER
  end
end

class Player
  attr_reader :marker
  attr_accessor :score

  def initialize(marker)
    @marker = marker
    @score = 0
  end

  def reset_score
    @score = 0
  end
end

class TTTGame
  HUMAN_MARKER = 'X'
  COMPUTER_MARKER = 'O'
  # FIRST_TO_MOVE = HUMAN_MARKER
  WINNING_SCORE = 2

  attr_reader :board, :human, :computer

  def initialize
    @board = Board.new
    @human = Player.new(HUMAN_MARKER)
    @computer = Player.new(COMPUTER_MARKER)
    # @current_marker = FIRST_TO_MOVE
    @first_to_move = nil
    @current_marker = nil
    @round = 1
  end

  def play
    clear
    display_welcome_message
    main_game
    display_goodbye_message
  end

  private

  def determine_first_to_move
    @first_to_move = case first_to_move_selection
                     when 1 then HUMAN_MARKER
                     when 2 then COMPUTER_MARKER
                     when 3 then [HUMAN_MARKER, COMPUTER_MARKER].sample
                     end

    @current_marker = @first_to_move
  end

  def first_to_move_selection
    puts
    puts 'Who would you like to go first? Press:'

    answer = nil
    loop do
      puts '1) You'
      puts '2) The computer'
      puts '3) Choose randomly'
      answer = gets.chomp.to_i
      break if answer.between?(1, 3)

      puts
      puts 'Sorry that is not a valid choice. Please try again.'
    end

    clear
    answer
  end

  def main_game
    loop do
      determine_first_to_move
      play_rounds
      display_game_result
      break unless play_again?

      reset_game
    end
  end

  def play_rounds
    loop do
      display_ui
      player_moves
      display_round_result
      break if game_winner?

      next_round_prompt
      update_round_num
      reset_round
    end
  end

  def display_game_result
    if human.score == WINNING_SCORE
      puts '******************************************'
      puts "You scored #{WINNING_SCORE} points and have won the game!"
      puts '******************************************'
    else
      puts '**************************************************'
      puts "The computer scored #{WINNING_SCORE} points and has won the game!"
      puts '**************************************************'
    end
  end

  def reset_game
    reset_round
    @round = 1
    human.reset_score
    computer.reset_score
  end

  def game_winner?
    [human.score, computer.score].include?(WINNING_SCORE)
  end

  def next_round_prompt
    puts
    puts '------------------------------------'
    puts "Press 'enter' to play the next round."
    gets.chomp
  end

  def player_moves
    loop do
      current_player_moves

      if board.someone_won?
        update_score
        break
      end

      break if board.full?

      clear_screen_and_display_ui if human_turn?
    end
  end

  def display_welcome_message
    puts 'Welcome to Tic Tac Toe!'
    puts
    puts "The first to score #{WINNING_SCORE} points wins the game."
    puts '------------------------------------------'
  end

  def display_goodbye_message
    puts
    puts 'Thanks for playing Tic Tac Toe! Goodbye!'
    puts
  end

  def clear_screen_and_display_ui
    clear
    display_ui
  end

  def display_ui
    display_round
    display_score
    display_board
    display_player_markers
  end

  def human_turn?
    @current_marker == HUMAN_MARKER
  end

  def display_player_markers
    puts "Your marker: \"#{human.marker}\". Computer marker: \"#{computer.marker}\"."
    puts
  end

  def display_round
    puts "************ Round #{@round} ************"
    puts
  end

  def display_score
    puts "Your score: #{human.score}. Computer score: #{computer.score}"
    puts
  end

  def display_board
    board.draw
    puts
  end

  def joinor(keys)
    case keys.size
    when 1 then keys.first
    when 2 then keys.join(' or ')
    else
      keys = keys.join(', ')
      keys[0..-2] + 'or ' + keys[-1]
    end
  end

  def human_moves
    puts "Choose a square (#{joinor(board.unmarked_keys)}): "
    square = nil
    loop do
      square = gets.chomp.to_i
      break if board.unmarked_keys.include?(square)

      puts
      puts "Sorry, that's not a valid choice."
    end

    board[square] = human.marker
  end

  def computer_moves
    square ||= board.find_at_risk_square(computer.marker)
    square ||= board.find_at_risk_square(human.marker)
    square ||= 5 if board.unmarked_square_5?
    square ||= board.unmarked_keys.sample
    board[square] = computer.marker
  end

  def current_player_moves
    if human_turn?
      human_moves
      @current_marker = COMPUTER_MARKER
    else
      computer_moves
      @current_marker = HUMAN_MARKER
    end
  end

  def display_round_result
    clear_screen_and_display_ui

    return if game_winner?

    case board.winning_marker
    when human.marker
      puts '### You won the round! ###'
    when computer.marker
      puts '### Computer won the round! ###'
    else
      puts "It's a tie!"
    end
  end

  def update_score
    case board.winning_marker
    when human.marker then human.score += 1
    when computer.marker then computer.score += 1
    end
  end

  def update_round_num
    @round += 1
  end

  def play_again?
    answer = nil
    loop do
      puts
      puts '-----------------------------------'
      puts 'Would you like to play again? (y/n)'
      answer = gets.chomp.downcase
      break if %w[y n].include? answer

      puts 'Sorry, must be y or n'
    end

    answer == 'y'
  end

  def clear
    system 'clear'
  end

  def reset_round
    board.reset
    @current_marker = @first_to_move
    # @current_marker = FIRST_TO_MOVE
    clear
  end
end

game = TTTGame.new
game.play
