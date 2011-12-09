source "http://rubygems.org"

gemspec

group :test do
  group :darwin do
    gem 'rb-fsevent'
  end

  # Solving runner bug: https://github.com/guard/guard-minitest/pull/25
  gem 'guard-minitest', :git => 'https://github.com/grimen/guard-minitest'
end

