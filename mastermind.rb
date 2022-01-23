require 'pry-byebug'

module Input
  def positive_integer_input
    positive_integer = gets.chomp.to_f
    until positive_integer.positive? && positive_integer.to_i == positive_integer
      puts 'Please type a valid positive integer.'
      positive_integer = gets.chomp.to_f
    end
    positive_integer.to_i
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

  class Game
    include Colors, Input

    def initialize
      puts "Let's play Mastermind! The peg colors are as follows."
      puts Colors
      puts 'How many guesses would you like to allow?'
      @guesses_allowed = positive_integer_input
      @codebreaker = Codebreaker.new
      @codemaker = Codemaker.new
      @history = {}.compare_by_identity
    end

    def play
      play_round until @game_over
    end

    private

    def play_round
      guess = @codebreaker.guess
      feedback = @codemaker.feedback(guess)
      @history[guess] = feedback
      display_history
      evaluate_game_over(guess)
    end

    def display_history
      puts "Guesses so far: #{@history.size}/#{@guesses_allowed}"
      @history.each_with_index do |(guess, feedback), i|
        puts "#{' ' * 5}Guess \##{i + 1}. #{guess.join}"
        puts feedback.split("\r\n").map { |line| line.prepend(' ' * 10) }.join("\r\n")
      end
    end

    def evaluate_game_over(guess)
      out_of_guesses = @history.size == @guesses_allowed
      correct_guess = @codemaker.code == guess
      return unless out_of_guesses || correct_guess

      @game_over = true
      if correct_guess
        puts "Congratulations #{@codebreaker.name}, you guessed the code!"
      else
        puts "Sorry #{@codebreaker.name}, you ran out of guesses."
      end
    end
  end

  class Codemaker
    include Colors
    attr_reader :code

    def initialize
      @code = 4.times.map { letters.sample }
      puts 'The computer has chosen a code with four peg colors.'
    end

    def feedback(guess)
      @correct_color_position = 0
      @correct_color = 0
      letters.each { |letter| give_letter_feedback(letter, guess) }
      "Pegs with correct color and position: #{@correct_color_position}\r\n" \
      "Pegs with correct color only: #{@correct_color}"
    end

    private

    def give_letter_feedback(letter, guess)
      letter_correct_color_position =
        guess.each_with_index
             .count { |guess_letter, i| guess_letter == code[i] && guess_letter == letter }
      @correct_color_position += letter_correct_color_position
      @correct_color += [guess.count(letter), code.count(letter)].min - letter_correct_color_position
    end
  end

  class Codebreaker
    include Colors
    attr_reader :name

    def initialize
      puts 'Codebreaker, what is your name?'
      @name = gets.chomp
    end

    def guess
      puts "Guess the code, #{name}! Type four letters for four colors (e.g., ROYG)."
      puts Colors.shorthand
      @guess = gets.chomp.upcase.split('')
      validate_guess
      @guess
    end

    private

    def valid_letters_only
      @guess.all? { |letter| letters.join.include?(letter) }
    end

    def validate_guess
      until @guess.size == 4 && valid_letters_only
        puts 'Please type FOUR letters (e.g., ROYG).' unless @guess.size == 4
        puts 'Please only type letters corresponding to valid colors.' unless valid_letters_only
        @guess = gets.chomp.upcase.split('')
      end
    end
  end
end

game = Mastermind::Game.new
game.play

# TODO: customizable total guesses allowed and code length
# TODO: make human and computer subclasses for codemaker and codebreaker once needed
