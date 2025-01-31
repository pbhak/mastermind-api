# frozen_string_literal: true

# Class containing computer guess algorithms
class Computer
  def initialize
    @all_possible_solutions = calculate_all_solutions
  end

  def calculate_all_solutions # rubocop:disable Metrics/MethodLength
    all_solutions = []

    (1..6).each do |i|
      (1..6).each do |j|
        (1..6).each do |k|
          (1..6).each do |l|
            all_solutions << [i, j, k, l]
          end
        end
      end
    end

    all_solutions
  end

  def get_score(feedback) # rubocop:disable Metrics/MethodLength
    # Obtains a "score" from given feedback in order to determine which guesses were better than others.
    # This assumes feedback is a Hash containing :exact, :near, and :none keys
    return 0 if feedback.empty?

    score = 0

    feedback.each do |category, nums_in_category|
      case category
      when :exact
        score += nums_in_category * 3
      when :near
        score += nums_in_category * 2
      when :none
        score += nums_in_category
      end
    end

    score
  end

  def get_feedback(correct_code, guess) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    feedback = Hash.new(0)
    code_distribution = correct_code.each_with_object(Hash.new(0)) { |peg, distrib| distrib[peg] += 1 }
    guess_distribution = guess.each_with_object(Hash.new(0)) { |peg, distrib| distrib[peg] += 1 }

    guess.each_with_index do |peg, index|
      if correct_code[index] == peg
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

    feedback
  end

  def place_guess(turn, previous_feedback, code)
    # Computer guess algorithm that uses the Knuth algorithm to calculate the
    # best move to play, given the turn number and the previous feedback object.
    # Can solve a game in 6 moves or less.
    return [1, 1, 2, 2] if turn == 1 # Best starting guess

    # Remove all entries from the possible guess list that have a score less than last guess's score
    @all_possible_solutions.select! do |solution|
      get_score(get_feedback(code, solution)) > get_score(previous_feedback)
    end

    # sleep (1..4).to_a.sample # Sleep for a random amount of seconds to make it seem like the computer is thinking

    # Return a random entry from the guess list
    @all_possible_solutions.sample
  end
end
