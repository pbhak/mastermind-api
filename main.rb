# frozen_string_literal: true

require 'sinatra'
require_relative 'lib/game'

set :port, 4567
set :environment, 'development' # TODO: switch to production before deployment

ALLOWED_ROLES = %w[cm cb codemaker codebreaker code_maker code_breaker code-maker code-breaker].freeze
ALLOWED_COLORS = [true, false, 'true', 'false', 'yes', 'no'].freeze

games = {}
before do
  content_type 'application/json'
  if request.body.read.empty?
    @request_body = {}
  else
    request.body.rewind
    @request_body = JSON.parse(request.body.read)
  end
end

not_found do
  JSON.generate(
    {
      error: '404 Not Found'
    }
  )
end

error 400 do
  JSON.generate(
    {
      error: '400 Bad Request'
    }
  )
end

error 500 do
  JSON.generate(
    {
      error: '500 Internal Server Error',
      message: env['sinatra.error'].message
    }
  )
end

error 410 do
  JSON.generate(
    {
      error: '410 Gone',
      message: 'Turns exceeded'
    }
  )
end

post '/new' do
  halt 400 unless @request_body.key?('role') && @request_body.key?('color')
  halt 400 unless ALLOWED_ROLES.include?(@request_body['role'].downcase)

  @request_body['color'] = @request_body['color'].downcase if @request_body['color'].instance_of?(String)
  halt 400 unless ALLOWED_COLORS.include?(@request_body['color'])

  code_breaker = ALLOWED_ROLES.index(@request_body['role'].downcase).odd?
  game = Game.new(code_breaker, @request_body['color'])
  games[game.id] = game

  status 201
  JSON.generate(
    {
      data: {
        id: game.id,
        colors: ALLOWED_COLORS.index(game.colors).even? ? true : false,
        role: ALLOWED_ROLES.index(@request_body['role']).even? ? 'code_maker' : 'code_breaker'
      }
    }
  )
end

post '/guess/:id' do |id|
  id = id.to_i

  halt 400 unless games.key?(id)
  halt 400 unless games[id].code_breaker
  halt 400 unless @request_body.key?('code')
  halt 400 unless @request_body['code'].is_a?(Array)
  halt 400 unless @request_body['code'].length == 4

  if games[id].turn == 12
    # game lost - remove game and raise HTTP 410 Gone
    games.delete(id)
    halt 410
  end

  feedback = games[id].guess(@request_body['code'])

  JSON.generate(
    {
      turn: games[id].turn - 1, # TODO: make sure it exits after 12 turns and not 13
      feedback: feedback,
      won: feedback[:exact] == 4
    }
  )
end

get '/games' do
  all_games = []
  games.each do |id, game|
    all_games << {
      id: id,
      colors: game.colors,
      role: game.code_breaker ? 'code_breaker' : 'code_maker',
      feedback: game.all_feedback,
      turn: game.turn
    }
  end

  JSON.generate(all_games)
end

get '/games/:id' do |id|
  games.each do |game_id, game|
    if game_id == id.to_i
      return JSON.generate(
        {
          id: id,
          colors: game.colors,
          role: game.code_breaker ? 'code_breaker' : 'code_maker',
          feedback: game.all_feedback,
          turn: game.turn
        }
      )
    end
  end

  halt 404
end

get '/games/:id/:attribute' do |id, attribute|
  halt 400 unless %w[id colors role feedback turn].include?(attribute.downcase)

  games.each do |game_id, game|
    next unless game_id == id.to_i

    case attribute
    when 'id' then return game_id.to_json
    when 'colors' then return game.colors.to_json
    when 'role' then return (game.code_breaker ? 'code_breaker' : 'code_maker').to_json
    when 'feedback' then return game.all_feedback.to_json
    when 'turn' then return game.turn.to_json
    end
  end
end

patch '/games/:id' do |id|
  id = id.to_i
  halt 400 unless id.is_a?(Integer) && id.digits.length == 3
  halt 400 if @request_body.empty?
  halt 404, "ID #{id} Not Found" unless games.key?(id)

  if @request_body.key?('color')
    @request_body['color'] = @request_body['color'].downcase if @request_body['color'].instance_of?(String)
    halt 400 unless ALLOWED_COLORS.include?(@request_body['color'])

    games[id].colors = @request_body['color']
  end

  if @request_body.key?('role')
    halt 400 unless ALLOWED_ROLES.include?(@request_body['role'].downcase)
    code_breaker = ALLOWED_ROLES.index(@request_body['role']).odd?

    games[id].code_breaker = code_breaker
  end

  JSON.generate(
    {
      data: {
        id: id,
        colors: ALLOWED_COLORS.index(games[id].colors).even? ? true : false,
        role: games[id].code_breaker ? 'code_breaker' : 'code_maker'
      }
    }
  )
end
