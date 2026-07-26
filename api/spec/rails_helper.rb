# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
# and is used by all request/feature specs.

ENV['RAILS_ENV'] ||= 'test'
ENV['SECRET_KEY_BASE'] ||= 'test_secret_key_base_for_rspec_ci_32chars'

require_relative '../config/environment'
require 'rspec/rails'
require 'sidekiq/testing'

Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

abort('The Rails environment is running in production mode!') if Rails.env.production?

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

Sidekiq::Testing.fake!

RSpec.configure do |config|
  config.fixture_path = Rails.root.join('spec/fixtures')
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.before(:suite) do
    Rack::Attack.enabled = false if defined?(Rack::Attack)
  end

  config.before do
    RequestStore.clear!
    Sidekiq::Worker.clear_all
  end

  config.include AuthHelpers, type: :request
  config.include JsonHelpers, type: :request
end
