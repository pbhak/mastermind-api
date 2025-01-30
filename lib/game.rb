# frozen_string_literal: true

# Main game class containing core functions
class Game
  attr_reader :all_feedback, :turn, :id
  attr_accessor :colors, :code_breaker

  COLOR_LIST = %w[🔴 🔵 🟢 🟠 🟣 🟡].freeze
  # 0: red, 1: blue, 2: green, 3: orange, 4: purple, 6: yellow

  @@all_ids = [] # rubocop:disable Style/ClassVars

  def initialize(code_breaker, colors = true) # rubocop:disable Style/OptionalBooleanParameter
    @colors = colors
    @code_breaker = code_breaker # boolean
    @code = code_breaker ? random_code : [] # correct code
    @current_guess = [] if code_breaker
    @all_feedback = {}
    @turn = 0
    @id = rand(100..999)
    @id = rand(100..999) while @@all_ids.include?(@id)

    @@all_ids << @id
  end

  def guess(guess) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    @current_guess = guess
    @turn += 1
    # feedback
    feedback = Hash.new(0)
    code_distribution = @code.each_with_object(Hash.new(0)) { |peg, distrib| distrib[peg] += 1 }
    guess_distribution = guess.each_with_object(Hash.new(0)) { |peg, distrib| distrib[peg] += 1 }

    guess.each_with_index do |peg, index|
      next unless guess_distribution[peg].positive?

      if @code[index] == peg
        feedback[:exact] += 1
        guess_distribution[peg] -= 1
        code_distribution[peg] -= 1
      elsif code_distribution.key?(peg)
        feedback[:near] += 1
        guess_distribution[peg] -= 1
        code_distribution[peg] -= 1
      else
        feedback[:none] += 1
      end
    end

    @all_feedback[@turn] = feedback
    feedback
  end

  # helper functions

  def create_code(code)
    @code = code
    to_colors(code)
  end

  def to_colors(code)
    code.map do |peg|
      COLOR_LIST[peg - 1]
    end
  end

  def random_code
    [rand(1..6), rand(1..6), rand(1..6), rand(1..6)]
  end

  def self.all_ids
    @@all_ids
  end
end
