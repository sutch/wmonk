module Wmonk
  class WebServer

    def initialize(copy, options = {})
      @options = {
        :port => 8111,
      }.merge(options)
      @copy = copy
    end

    def start
      Rack::Server.start :app => self, :Port => @options[:port]
    end

    # to be called by
    def call(env)
      @copy.resource_by_path(env['REQUEST_PATH'])
      [200, [], [@copy.resource_by_path(env['REQUEST_PATH']).body]]
    end

  end
end
