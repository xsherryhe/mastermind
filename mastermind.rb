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
      @history = []
    end

    def play_round
      @codebreaker.make_guess
      p @codebreaker.guess
    end
  end

  class Codemaker
    include Colors
    attr_reader :code

    def initialize
      @code = 4.times.map { letters.sample }
      puts 'The computer has chosen a code with four peg colors.'
    end
  end

  class Codebreaker
    include Colors
    attr_reader :name, :guess

    def initialize
      puts 'Codebreaker, what is your name?'
      @name = gets.chomp
    end

    def make_guess
      puts "Guess the code, #{name}! Type four letters for four colors (e.g., ROYG)."
      puts Colors.shorthand
      @guess = gets.chomp.upcase
      validate_guess
    end

    private

    def valid_letters_only
      @guess.chars.all? { |char| letters.join.include?(char) }
    end

    def validate_guess
      until @guess.length == 4 && valid_letters_only
        puts 'Please type FOUR letters (e.g., ROYG).' unless guess.length == 4
        puts 'Please only type letters corresponding to valid colors.' unless valid_letters_only
        @guess = gets.chomp.upcase
      end
    end
  end
end

game = Mastermind::Game.new
game.play_round

# TODO: codemaker method to give feedback using pegs)
# TODO: game over conditions
# TODO: make human and computer subclasses for codemaker and codebreaker once needed
