source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "~> 3.4.0"

gem "rails", "~> 8.1.0"
gem "sprockets-rails"
gem "pg", "~> 1.5"
gem "puma", "~> 6"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]
gem "bootsnap", require: false

# Auth
gem "bcrypt", "~> 3.1.7"
gem "jwt", "~> 2.7"

# CORS for Flutter client
gem "rack-cors"

# Pagination
gem "kaminari"

group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
end

group :development do
  gem "solargraph"
  gem "erb_lint"
  gem "hotwire-livereload", "~> 1.2"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
