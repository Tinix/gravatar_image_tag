# frozen_string_literal: true

source 'https://rubygems.org'

rails_version = ENV['RAILS_VERSION'] || 'default'

rails = case rails_version
        when 'master'
          { github: 'rails/rails' }
        when 'default'
          '~> 3.2.0'
        else
          "~> #{rails_version}"
        end

group :development, :test do
  gem 'actionpack', rails
  gem 'activesupport', rails
  gem 'rspec'
end

group :development do
  gem 'guard'
  gem 'guard-rspec'
  gem 'jeweler'
  gem 'rb-fsevent', '~> 0.9'
end
