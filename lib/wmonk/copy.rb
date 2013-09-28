require 'sqlite3'
require 'active_record'
require 'wmonk/database_migration'

Dir[File.dirname(__FILE__) + '/models/**/*.rb'].each {|file| require file }  # ActiveRecord models

module Wmonk

  # Representation of a website copy created by wmonk.
  class Copy

    # @return [String] Returns the path to wmonk's working folder for the website
    attr_reader :path

    def initialize(path)
      @path = path

      ActiveRecord::Base.establish_connection(
          :adapter => 'sqlite3',
          :database => (Pathname.new(@path) + 'copy.db').to_s,
          :timeout => 500,
          :pool => 10000,
          :reaping_frequency => 60,
      )
    end

    def create
      Wmonk::DatabaseMigration.migrate(:up)
    end

  end

end
