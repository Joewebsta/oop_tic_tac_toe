# frozen_string_literal: true

class Board
  SIZE = 3
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

  def unmarked_priority_square?
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
      return squares.first.marker if full_row_identical_markers?(squares)
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

      next unless markers.count(marker) == (SIZE - 1) &&
                  squares.one?(&:unmarked?)

      third_square = squares.select(&:unmarked?).first
      return @squares.key(third_square)
    end

    nil
  end

  private

  def full_row_identical_markers?(squares)
    markers = squares.select(&:marked?).map(&:marker)
    return false if markers.size != SIZE

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
  attr_accessor :score

  def initialize
    @score = 0
  end

  def reset_score
    @score = 0
  end
end

class Human < Player
  attr_accessor :name, :marker

  def set_name
    set_name_prompt
    self.name = select_name
    clear
  end

  def set_marker
    set_marker_prompt
    self.marker = select_marker
    clear
  end

  private

  def set_name_prompt
    puts '**** Name Selection ****'
    puts
    puts 'What is your name?'
  end

  def select_name
    answer = nil
    loop do
      answer = gets.chomp
      break if answer.length >= 1 && answer.squeeze != ' '

      puts 'Your answer must not be blank. Please try again.'
    end
    answer
  end

  def set_marker_prompt
    puts '**** Marker Selection ****'
    puts
    puts "Select your marker (e.g. 'X', '$', or 'a')."
    puts "- Note: The compter's marker is 'O'."
  end

  def select_marker
    answer = nil
    loop do
      answer = gets.chomp
      break if answer.length == 1 &&
               answer.downcase != 'o' &&
               answer.squeeze != ' '

      invalid_marker_msg(answer)
    end

    answer
  end

  def invalid_marker_msg(answer)
    puts
    puts 'Sorry that is not a valid choice. Please try again.'
    puts '- Note: Your marker must be a single character.' if answer.length != 1
    puts '- Note: Your marker must not be a space.' if answer.squeeze == ' '

    if answer.downcase == Computer::MARKER.downcase
      puts "- Note: The computer's marker is #{Computer::MARKER}."
    end
  end

  def clear
    system 'clear'
  end
end

class Computer < Player
  MARKER = 'O'
  NAMES = %w(BumbleBee C3P0 Robocop Wall-E).freeze
  PRIORITY_SQUARE = 5

  attr_reader :name, :marker

  def initialize
    @name = NAMES.sample
    @marker = MARKER
    super
  end
end

class TTTGame
  WINNING_SCORE = 5

  attr_reader :board, :human, :computer

  def initialize
    @board = Board.new
    @human = Human.new
    @computer = Computer.new
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

  def display_welcome_message
    puts '********* Welcome to Tic Tac Toe! *********'
    puts
    puts "The first to score #{WINNING_SCORE} points wins the game."
    puts '------------------------------------------'
    puts
  end

  def main_game
    loop do
      set_name_and_marker
      determine_first_to_move
      play_rounds
      display_game_result
      break unless play_again?

      reset_game
    end
  end

  def set_name_and_marker
    human.set_name
    human.set_marker
  end

  def determine_first_to_move
    @first_to_move = case first_to_move_selection
                     when 1 then human.marker
                     when 2 then computer.marker
                     when 3 then [human.marker, computer.marker].sample
                     end

    @current_marker = @first_to_move
  end

  def first_to_move_selection
    puts '**** Player Order ****'
    puts
    puts 'Who would you like to go first? Select:'
    puts
    answer = first_to_move_answer
    clear
    answer
  end

  def first_to_move_answer
    answer = nil
    loop do
      puts "1) You \n2) The computer \n3) Choose randomly"
      answer = gets.chomp
      break if answer.to_i.between?(1, 3) && answer.length == 1

      puts
      puts 'Sorry that is not a valid choice. Please try again.'
      puts
    end

    answer.to_i
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

  def display_ui
    display_round
    display_score
    display_board
    display_player_markers
  end

  def clear_screen_and_display_ui
    clear
    display_ui
  end

  def display_round
    puts "************ Round #{@round} ************"
    puts
  end

  def display_score
    puts "#{human.name}'s score: #{human.score}. " \
         "#{computer.name}'s score: #{computer.score}"
    puts
  end

  def display_board
    board.draw
    puts
  end

  def display_player_markers
    puts "#{human.name}'s marker: #{human.marker} -- " \
         "#{computer.name}'s marker: #{computer.marker}"
    puts
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

  def current_player_moves
    if human_turn?
      human_moves
      @current_marker = computer.marker
    else
      computer_moves
      @current_marker = human.marker
    end
  end

  def human_turn?
    @current_marker == human.marker
  end

  def human_moves
    puts "Choose a square (#{joinor(board.unmarked_keys)}): "
    square = choose_square_key
    board[square] = human.marker
  end

  def choose_square_key
    square = nil
    loop do
      square = gets.chomp
      break if board.unmarked_keys.include?(square.to_i) &&
               square.length == 1
      puts
      puts "Sorry, that's not a valid choice."
    end

    square.to_i
  end

  def computer_moves
    square ||= at_risk_square
    square ||= unmarked_priority_square
    square ||= random_unmarked_key
    board[square] = computer.marker
  end

  def at_risk_square
    board.find_at_risk_square(computer.marker) ||
      board.find_at_risk_square(human.marker)
  end

  def unmarked_priority_square
    Computer::PRIORITY_SQUARE if board.unmarked_priority_square?
  end

  def random_unmarked_key
    board.unmarked_keys.sample
  end

  def update_score
    case board.winning_marker
    when human.marker then human.score += 1
    when computer.marker then computer.score += 1
    end
  end

  def display_round_result
    clear_screen_and_display_ui
    return if game_winner?

    display_round_result_message
  end

  def display_round_result_message
    case board.winning_marker
    when human.marker
      puts "### #{human.name} won the round! ###"
    when computer.marker
      puts "### #{computer.name} won the round! ###"
    else
      puts "It's a tie!"
    end
  end

  def next_round_prompt
    puts
    puts '------------------------------------'
    puts "Press 'enter' to play the next round."
    gets.chomp
  end

  def update_round_num
    @round += 1
  end

  def reset_round
    board.reset
    @current_marker = @first_to_move
    clear
  end

  def game_winner?
    [human.score, computer.score].include?(WINNING_SCORE)
  end

  def display_game_result
    if human.score == WINNING_SCORE
      puts '******************************************'
      puts "#{human.name} scored #{WINNING_SCORE} points and has won the game!"
      puts '******************************************'
    else
      puts '**************************************************'
      puts "#{computer.name} scored #{WINNING_SCORE} points and has won the game!"
      puts '**************************************************'
    end
  end

  def reset_game
    reset_round
    @round = 1
    human.reset_score
    computer.reset_score
  end

  def play_again?
    answer = nil
    loop do
      puts
      puts '-----------------------------------'
      puts 'Would you like to play again? (y/n)'
      answer = gets.chomp.downcase
      break if %w(y n).include? answer

      puts 'Sorry, must be y or n.'
    end

    answer == 'y'
  end

  def display_goodbye_message
    puts
    puts 'Thanks for playing Tic Tac Toe! Goodbye!'
    puts
  end

  def clear
    system 'clear'
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
end

game = TTTGame.new
game.play
