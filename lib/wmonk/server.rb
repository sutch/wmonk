require 'yaml'
module Wmonk
  class Server

    def initialize(copy, options = {})
      @options = {
          :type => :web,
      }.merge(options)
      @copy = copy
    end

    def call(env)
      if @options[:type] == :web
        @copy.resource_by_path(env['REQUEST_PATH'])
        [200, [], [@copy.resource_by_path(env['REQUEST_PATH']).body]]
      elsif @options[:type] == :info
        response =<<END
<html>
<head>
<title>Wmonk server</title>
</head>
<body>
<h1>Wmonk server</h1>
<h2>Site information</h2>
<ul>
<li>Location of website copy: #{@copy.path}</li>
<li>Base URL: #{@copy.base_url}</li>
<li>Number of resources: #{@copy.resource_count}</li>
</ul>
<h2>Resources</h2>
<ol>
END

        @copy.each_resource {|r| response += "<li>#{r[0]} [#{r[1]}] (#{r[2]})</li>"}

response +=<<END2
</ol>
</body>
</html>
END2

        [200, {}, [response]]
      end
    end

  end
end
