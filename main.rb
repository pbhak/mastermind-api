# frozen_string_literal: true

require 'sinatra'
require_relative 'lib/game'

set :port, 4567
set :environment, 'development' # TODO: switch to production before deployment

ALLOWED_ROLES = %w[cm cb codemaker codebreaker code_maker code_breaker code-maker code-breaker].freeze
ALLOWED_COLORS = [true, false, 'yes', 'no'].freeze

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
  "Not Found #{request.path_info}"
end

error 400 do
  '400 Bad Request'
end

error 500 do
  env['sinatra.error'].message
end

post '/new' do
  halt 400 if @request_body.empty?
  halt 400 unless @request_body.key?('role') && @request_body.key?('colors')
  halt 400 unless ALLOWED_ROLES.include?(@request_body['role'].downcase)
  
  @request_body['color'] = @request_body['color'].downcase if @request_body['color'].instance_of?(String)
  halt 400 unless ALLOWED_COLORS.include?(@request_body['color'])

  code_breaker = ALLOWED_ROLES.index(@request_body['role'].downcase).odd?
  game = Game.new(@request_body['role'], @request_body['color'])
  games[game.id] = game

  JSON.generate(
    {
      data: {
        id: game.id,
        colors_enabled: game.colors,
        role: @request_body['role']
      }
    }
  )

  201
end

patch '/update/:id' do |id|
  halt 400 unless id.is_a?(Integer) && id.digits.length == 3 
  halt 400 if @request_body.empty?
  halt 404 , "ID #{id} Not Found" unless games.key?(id)
  
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
        colors_enabled: games[id].colors,
        role: @request_body[['role']]
      }
    }
  )
end