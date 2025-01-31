# frozen_string_literal: true

require_relative 'computer'

# Main game class containing core functions
class Game
  attr_reader :all_feedback, :id, :computer
  attr_accessor :code_breaker, :turn, :code

  @@all_ids = [] # rubocop:disable Style/ClassVars

  def initialize(code_breaker) # rubocop:disable Style/OptionalBooleanParameter
    @code_breaker = code_breaker # boolean
    @code = random_code # leaving this here to make randomization default
    @computer = Computer.new
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
      if @code[index] == peg
        feedback[:exact] += 1
        guess_distribution[peg] -= 1
        code_distribution[peg] -= 1
      elsif code_distribution[peg].positive? && code_distribution[peg] == guess_distribution[peg]
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

  def random_code
    [rand(1..6), rand(1..6), rand(1..6), rand(1..6)]
  end

  def self.all_ids
    @@all_ids
  end
end
