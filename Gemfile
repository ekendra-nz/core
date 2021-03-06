source "https://rubygems.org"

group :default do # XXX: all environments, think twice before adding Gems here
  gem "rake"
  gem "test-unit" # for Ruby 2.2+
  gem "unicorn"
  gem "rails", git: "https://github.com/infertux/rails.git", branch: "3-2-stable" # use our own 3.2 fork with backported patches...
  gem "sprockets"
  gem "rails-i18n", "~> 3.0.0" # for Rails 3.x
  gem "pg"
  gem "therubyracer"
  gem "haml-rails"
  gem "jquery-rails"
  gem "jquery-ui-rails"
  gem "bootstrap-sass", "< 3"
  gem "bootbox-rails"
  gem "select2-rails", "< 4" # TODO: upgrade? https://select2.github.io/announcements-4.0.html
  gem "hiredis"
  gem "readthis", "< 1" # TODO: upgrade when 1.0.0 is stable
  gem "devise"
  gem "devise-i18n"
  gem "simple_form", "< 3"
  gem "inherited_resources"
  gem "mini_magick"
  gem "carrierwave"
  gem "acts-as-taggable-on"
  gem "pg_search"
  gem "whenever"
  gem "acts_as_list"
  gem "default_value_for"
  gem "state_machine"
  gem "figaro"
  gem "virtus"
  gem "draper", "< 2" # Rails 3.2 not supported with v2
  gem "naught"
  gem "premailer-rails"
  gem "nokogiri" # premailer-rails dependency
  gem "delayed_job"
  gem "delayed_job_active_record"
  gem "delayed_job_web"
  gem "daemons" # needed for script/delayed_job
  gem "analytical", git: "https://github.com/jkrall/analytical.git" # released version doesn't allow setting the key in controller
  gem "ace-rails-ap"
  gem "active_utils"
  gem "activemerchant"
  gem "countries"
  gem "country_select", "~> 1.1.3" # TODO: https://github.com/stefanpenner/country_select/blob/master/UPGRADING.md
  gem "biggs"
  gem "charlock_holmes"
  gem "rabl"
  gem "apipie-rails"
  gem "strong_parameters"
  gem "rails-timeago"
  gem "fast_blank"
  gem "retryable"
  gem "rails-patch-json-encode"
  gem "oj"
  gem "crazy_money"
  gem "currency_data"
  gem "email_templator"
  gem "simple_form-bank_account_number"
  gem "ordinalize_full", require: "ordinalize_full/integer"
  gem "librato-rails"
  gem "rbtrace"
  gem "geokit-rails"
  gem "typhoeus"
  gem "rack-cors"
  gem "marginalia"
  gem "secure_headers", "< 4" # TODO: upgrade
  gem "bugsnag"

  gem "eu_central_bank", require: false
  gem "monetize", require: false
  gem "paypal-sdk-rest", require: false
  gem "xero_gateway", require: false
end

group :development do
  gem "webrick" # included explicitly so #chunked warnings no longer show up in the dev log
  gem "yard",       require: false
  gem "brakeman",   require: false
  gem "xray-rails", require: false
  gem "term-ansicolor"
  gem "parallel_tests"
  gem "sextant"
  gem "better_errors"
  gem "binding_of_caller"
  gem "quiet_assets"
  gem "meta_request"
  gem "i15r", require: false
end

group :test do
  gem "database_cleaner"
  gem "simplecov", require: false
  gem "cucumber-rails", require: false
  gem "capybara", require: false
  gem "capybara-screenshot"
  gem "poltergeist", require: false
  gem "launchy"
  gem "guard-rspec"
  gem "i18n-spec"
  gem "rspec-activemodel-mocks"
end

group :staging do
  gem "mail_safe"
end

group :development, :test do
  gem "fabrication"
  gem "rspec-rails"
  gem "listen"
  gem "terminal-notifier-guard" # Mac 10.8 system notifications for Guard
  gem "letter_opener"
  gem "bundler-audit", require: false
  gem "bullet", "~> 5.3.0" # TODO: upgrade
  gem "rubocop"
  gem "byebug"
  gem "cane"
  gem "pry-byebug"
  gem "pry-rails"
  gem "pry-coolline" # as-you-type syntax highlighting
  gem "pry-stack_explorer"
end

group :development, :test, :staging do
  gem "delorean"
end

group :assets do
  gem "coffee-rails"
  gem "uglifier"
  gem "sass-rails"
  gem "compass-rails"
end
