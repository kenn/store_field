require 'rubygems'
require 'bundler/setup'

require 'store_field'

RSpec.configure do |config|
  ActiveRecord::Base.send(:include, StoreField)

  # Establish in-memory database connection
  ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
end
