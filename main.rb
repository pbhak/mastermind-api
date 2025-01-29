# frozen_string_literal: true

require 'sinatra'

set :port, 4567
set :environment, 'development' # TODO: switch to production before deployment

before do
  content_type 'application/json'
end

# TODO: 400/404 (not_found)/500 error handling
