require 'pry-byebug'

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
    include Colors

    def initialize
      puts "Let's play Mastermind! The peg colors are as follows."
      puts Colors
      @codebreaker = Codebreaker.new
      @codemaker = Codemaker.new
      @history = {}
      @history.compare_by_identity
    end

    def play_round
      guess = @codebreaker.guess
      feedback = @codemaker.feedback(guess)
      @history[guess] = feedback
      display_history
    end

    private

    def display_history
      puts guesses_so_far
      @history.each_with_index do |(guess, feedback), i|
        puts "#{' ' * 5}Guess \##{i + 1}. #{guess.join}"
        puts feedback.split("\r\n").map { |line| line.prepend(' ' * 10) }.join("\r\n")
      end
    end

    def guesses_so_far
      "Guesses so far: #{@history.size}/12"
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
12.times { game.play_round }

# TODO: game over conditions
# TODO: customizable total guesses allowed and code length
# TODO: make human and computer subclasses for codemaker and codebreaker once needed
