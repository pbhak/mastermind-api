# frozen_string_literal: true

require 'sinatra'

set :port, 4567
set :environment, 'development' # TODO: switch to production before deployment

ALLOWED_ROLES = %w[cm cb codemaker codebreaker code_maker code_breaker code-maker code-breaker].freeze

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

get '/new' do
  halt 400 if @request_body.empty?
  halt 400 unless @request_body.key?('role')
  halt 400 unless ALLOWED_ROLES.include?(@request_body['role'].downcase)

  @request_body['role'] = @request_body['role'].downcase
  # cm - index of role even
  # cb - index of role odd
end