module Wmonk

  # Representation of a website copy created by wmonk.
  class Copy

    # @return [String] Returns the path to wmonk's working folder for the website
    attr_reader :path

    # @return [String] Returns the base URL (scheme and hostname) of the website
    attr_reader :base_url

    # Create an object to represent wmonk's copy of the website
    #
    # @param (String) path the path to wmonk's working forlder for the website
    def initialize(path)
      @path = path

      if ! File.exists? @path
        raise "working folder not found - #{@path}"
      end

      @conf_filename = Pathname.new(@path) + 'spider.yaml'
      if ! File.exists? @conf_filename
        raise "configuration file not found - #{@conf_filename}"
      end

      begin
        @conf = YAML::load(File.open(@conf_filename, 'r'))
      rescue Exception => e
        raise e.message
      end

      host = port = scheme = nil
      @conf['seed_urls'].each do |u|
        u = URI.parse u
        u.scheme = u.scheme.downcase
        raise "#{u.scheme} scheme not supported: #{u}" if ! ['http', 'https'].include? u.scheme
        u.host = u.host.downcase
        if host == nil
          host = u.host
          port = u.port
          scheme = u.scheme
        end
        if host != u.host or port != u.port or scheme != u.scheme
          url_1 = URI.parse("#{scheme}://#{host}:#{port}").to_s
          url_2 = URI.parse("#{u.scheme}://#{u.host}:#{u.port}").to_s
          raise "multiple websites not supported: requested #{url_1} and #{url_2}"
        end
      end
      @base_url = URI.parse("#{scheme}://#{host}:#{port}").to_s

      @sqlite_filename = Pathname.new(@path) + 'spider.sqlite'
      if ! File.exists? @sqlite_filename
        raise "sqlite file not found - #{@sqlite_filename}"
      end

      begin
        @db = SQLite3::Database.open @sqlite_filename.to_s
        @db.busy_timeout 17
      rescue Exception => e
        raise e.message
      end

    end

    # Number of resources.
    #
    # @return [Integer]
    # @note The count includes all URLs, whether wmonk successfully retrieved, unsuccessfully retrieved, or did not attempt to retrieve.
    def resource_count
      rows = 0
      @db.execute( "select count(*) from anemone_storage" ) do |row|
        rows = row[0]
      end
      rows
    end

    # Obtain a resource.
    #
    # @example
    #   resource = website.resource_by_path('/index.html')
    # @param [String] path the URL path identifying the resource on the website
    # @return [Anemone::Resource] the resource
    # @note The base_url of the spidered website is used to construct the full URL.
    def resource_by_path(path)
      url = (URI(self.base_url) + path).to_s
      rows = @db.execute( "select data from anemone_storage where key=?", url )
      # TODO: error if URL results in multiple resources
      Marshal.load(rows[0][0])  # return first column (the 'data' field) of first row
    end

    # Iterate through all resources. Block is passed an Anemone::Resource object.
    #
    # @example
    #   website.each_resource do {|r| puts "URL: #{r[0]}" }
    def each_resource
      rows = @db.execute( "select key, code, content_type from anemone_storage")
      rows.each do |resource|
        yield(resource)
      end
    end

  end

end
