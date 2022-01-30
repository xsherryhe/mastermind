require 'pry-byebug'

module GlobalInputValidation
  def integer_input(message = 'Please type a valid integer.', &condition)
    integer = gets.chomp.to_f
    until condition.call(integer) && integer.to_i == integer
      puts message
      integer = gets.chomp.to_f
    end
    integer.to_i
  end

  def integer_in_range(start, finish)
    integer_input("Please type a valid integer between #{start} and #{finish}.") do |integer|
      integer.between?(start, finish)
    end
  end
end

module Mastermind
  module Colors
    COLORS = { R: 'red',
               O: 'orange',
               Y: 'yellow',
               G: 'green',
               B: 'blue',
               P: 'purple' }
             .freeze

    def letters
      COLORS.keys.map(&:to_s)
    end

    def sample_letters
      @code_length.times.map { letters.sample }
    end

    def self.to_s
      join_colors("\r\n")
    end

    def self.shorthand
      "(#{join_colors(', ')})"
    end

    def self.join_colors(separator)
      COLORS.map { |letter, color| "#{letter}: #{color}" }.join(separator)
    end

    private_class_method :join_colors
  end

  module InputValidation
    include GlobalInputValidation

    private

    def valid_code_length_input
      integer_in_range(1, 6)
    end

    def valid_guesses_allowed_input
      integer_in_range(1, 1_000_000)
    end

    def valid_game_mode_input
      valid_game_mode = gets.chomp
      until valid_game_mode =~ /^[ABCDEF]$/i
        puts 'Please type one letter (A, B, C, D, E, or F) to select the corresponding game mode.'
        valid_game_mode = gets.chomp
      end
      valid_game_mode.upcase
    end

    def valid_code_instruction
      "Type #{@code_length} letters for #{@code_length} colors (e.g., #{sample_code}).\r\n" + Colors.shorthand
    end

    def valid_code_input
      valid_code = gets.chomp.upcase.split('')
      until valid_code.size == @code_length && valid_letters_only(valid_code)
        puts "Please type #{@code_length} letters (e.g., #{sample_code})." unless valid_code.size == @code_length
        puts 'Please only type letters corresponding to valid colors.' unless valid_letters_only(valid_code)
        valid_code = gets.chomp.upcase.split('')
      end
      valid_code
    end

    def valid_feedback_input(max_length)
      integer_in_range(0, max_length)
    end

    def sample_code
      sample_letters.join
    end

    def valid_letters_only(input)
      input.all? { |letter| letters.join.include?(letter) }
    end
  end

  module AutoFeedback
    attr_reader :code

    def feedback(guess, expected = code)
      @correct_color_position = 0
      @correct_color = 0
      letters.each { |letter| give_letter_feedback(letter, guess, expected) }
      [@correct_color_position, @correct_color]
    end

    private

    def give_letter_feedback(letter, guess, expected)
      letter_correct_color_position =
        guess.each_with_index
             .count { |guess_letter, i| guess_letter == expected[i] && guess_letter == letter }
      @correct_color_position += letter_correct_color_position
      @correct_color += [guess.count(letter), expected.count(letter)].min - letter_correct_color_position
    end
  end

  class Player
    include Colors

    def initialize(code_length)
      @code_length = code_length
    end
  end

  class Human < Player
    include InputValidation
    attr_reader :name

    def initialize(code_length)
      super
      @name = gets.chomp
    end
  end

  class Computer < Player
    include AutoFeedback

    def name
      'Computer'
    end
  end

  class ComputerCodemaker < Computer
    def initialize(code_length)
      super
      @code = sample_letters
      puts "The computer has chosen a code with #{@code_length} peg colors."
    end
  end

  class HumanCodemaker < Human
    def initialize(code_length)
      puts 'Codemaker, what is your name?'
      super
      puts "#{name}, please decide on a code with #{@code_length} peg colors. Keep it a secret!"
      puts 'Press ENTER to continue.'
      gets
    end

    def feedback(_guess)
      puts "#{name}, how many pegs in the guess have the correct color AND position?"
      correct_color_position = valid_feedback_input(@code_length)
      puts "#{name}, how many pegs in the guess have ONLY the correct color" \
           ' (EXCLUDING the ones in the correct position)?'
      correct_color = valid_feedback_input(@code_length - correct_color_position)
      [correct_color_position, correct_color]
    end
  end

  class AutoHumanCodemaker < Human
    include AutoFeedback

    def initialize(code_length)
      puts 'Codemaker, what is your name?'
      super
      puts "Make your secret code, #{name}! " + valid_code_instruction
      @code = valid_code_input
    end
  end

  class HumanCodebreaker < Human
    def initialize(code_length)
      puts 'Codebreaker, what is your name?'
      super
    end

    def guess
      puts "Guess the code, #{name}! " + valid_code_instruction
      valid_code_input
    end
  end

  class ComputerCodebreaker < Computer
    attr_reader :possible_guesses

    def initialize(code_length)
      super
      @possible_guesses = all_possible_guesses
      @guess = first_guess
    end

    def guess
      @guess = possible_guesses.first unless possible_guesses.include?(@guess)
      puts "The computer guesses #{@guess.join}."
      @guess
    end

    def process_feedback(expected_feedback)
      @possible_guesses.select! { |possible_guess| feedback(@guess, possible_guess) == expected_feedback }
    end

    private

    def all_possible_guesses
      letters.repeated_permutation(@code_length).to_a
    end

    def first_guess
      letter_guesses = letters.sample(2)
      half_code_length = @code_length / 2
      [letter_guesses.first] * half_code_length + [letter_guesses.last] * (@code_length - half_code_length)
    end
  end

  class Game
    include InputValidation
    include Colors

    def initialize
      puts "Let's play Mastermind! The peg colors are as follows."
      puts Colors
      puts 'How many pegs would you like the code to have? (How long should the code be?)'
      @code_length = valid_code_length_input
      puts 'How many guesses would you like to allow?'
      @guesses_allowed = valid_guesses_allowed_input
      @codebreaker, @codemaker = player_classes.map { |player| player.new(@code_length) }
      @history = {}.compare_by_identity
    end

    def play
      play_round until @game_over
    end

    private

    def game_mode_descriptions
      ['A: Computer vs Computer.', '   Watch two computers play.',
       'B: Human vs Computer.', '   Play as the Codebreaker against a Computer Codemaker.',
       'C: Computer vs Human.', '   Play as the Codemaker against a Computer Codebreaker.',
       '   Give your own feedback to the Computer.',
       'D: Computer vs AutoHuman.', '   Play as the Codemaker against a Computer Codebreaker.',
       '   Input your code into the game.', '   The game automatically generates feedback to the Computer.',
       'E: Human vs Human.', '   Two-player mode.',
       'F: Human vs AutoHuman.', '   Two-player mode with automatically generated feedback.']
        .map { |line| line.prepend(' ' * 5) }
        .join("\r\n")
    end

    def game_modes
      { A: [ComputerCodebreaker, ComputerCodemaker],
        B: [HumanCodebreaker, ComputerCodemaker],
        C: [ComputerCodebreaker, HumanCodemaker],
        D: [ComputerCodebreaker, AutoHumanCodemaker],
        E: [HumanCodebreaker, HumanCodemaker],
        F: [HumanCodebreaker, AutoHumanCodemaker] }
    end

    def player_classes
      puts 'Select your game mode. (Type A, B, C, D, E, or F)'
      puts game_mode_descriptions
      game_mode = valid_game_mode_input
      game_modes[game_mode.to_sym]
    end

    def play_round
      guess = @codebreaker.guess
      feedback = @codemaker.feedback(guess)
      @codebreaker.process_feedback(feedback) if @codebreaker.is_a?(Computer)
      @history[guess] = feedback
      display_history
      evaluate_game_over
    end

    def display_history
      puts "Guesses so far: #{@history.size}/#{@guesses_allowed}"
      @history.each_with_index do |(guess, feedback), i|
        puts "#{' ' * 5}Guess \##{i + 1}. #{guess.join}"
        puts ["Pegs with correct color and position: #{feedback.first}",
              "Pegs with correct color only: #{feedback.last}"]
          .map { |line| line.prepend(' ' * 10) }
          .join("\r\n")
      end
    end

    def evaluate_game_over
      return unless game_over_index

      @game_over = true
      puts ["Congratulations #{@codebreaker.name}, you guessed the code!",
            "Sorry #{@codebreaker.name}, you ran out of guesses.",
            'Based on your feedback, there is no code that works here.'][game_over_index]
      puts "The code was #{@codemaker.code.join}." if @codemaker.is_a?(AutoFeedback)
    end

    def game_over_index
      correct_guess = @history.values.last.first == @code_length
      out_of_guesses = @history.size == @guesses_allowed
      impossible_code = @codebreaker.is_a?(Computer) && @codebreaker.possible_guesses.empty?
      [correct_guess, out_of_guesses, impossible_code].index(true)
    end
  end
end

game = Mastermind::Game.new
game.play

# TODO: implement start a new game? loop
# TODO: implement tighter Knuth strategy
