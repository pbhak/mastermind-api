# frozen_string_literal: true

# Main game class containing core functions
class Game
  @@all_ids = [] # rubocop:disable Style/ClassVars

  def initialize(code_breaker, colors: true)
    @colors = colors
    @code_breaker = code_breaker # boolean
    @id = rand(100..999)

    @@all_ids << @id
  end

  def self.all_ids
    @@all_ids
  end
end
