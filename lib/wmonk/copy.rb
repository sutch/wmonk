require 'sqlite3'
require 'active_record'

module Wmonk

  class CreateDB < ActiveRecord::Migration
    def up
      create_table :urls do |t|
        t.text :url, null: false
        t.timestamps
      end
      create_table :exchanges do |t|  # HTTP exchange
        t.integer :url_id, null: false
        t.string :status_code
        t.string :content_type
        t.integer :body_id
        t.timestamps
      end
      create_table :bodies do |t|  # HTTP response message body
        t.binary :body, null: false
        t.text :digest, null: false
        t.timestamps
      end
      create_table :links do |t|  # instances of URLS within content
        t.integer :url_id, null: false
        t.integer :body_id, null: false
        t.timestamps
      end
    end
  end

  # Representation of a website copy created by wmonk.
  class Copy

    class Url < ActiveRecord::Base
      has_one :exchange
      has_many :links
    end

    class Exchange < ActiveRecord::Base
      belongs_to :url
      belongs_to :body
    end

    class Body < ActiveRecord::Base
      has_many :exchanges
      has_many :links

      after_initialize :init

      def init
        @body_is_parsed = []
        @base = {}
      end

      def links(options = {})
        # raise error if options not provided
        options = {
            :resource_url => nil,
            :content_type => nil,
            :project => nil,
        }.merge(options)

        # todo: handle situations where content-type is different for one body (i.e., body available through multiple URLs and each URL returns different content-type for same body)
        if @links.nil?
          @links = []
          ContentUrls.urls(body, options[:content_type]).each do |u|
            next if u.nil? or u.empty?
            @links << u
          end
          @links.uniq!
        end

        absolute_links = []
        @links.each do |link|
          abs = to_absolute(link, resource_url: options[:resource_url], content_type: options[:content_type]) rescue next
          next if !options[:project].url_in_scope?(abs)
          absolute_links << abs
        end
        absolute_links.uniq!

        absolute_links
      end


      def to_absolute(link, options = {})
        # raise error if options not provided
        options = {
            :resource_url => nil,
            :content_type => nil,
        }.merge(options)

        return nil if link.nil?

        # remove anchor
        link = URI.encode(URI.decode(link.to_s.sub(/##{URI(link).fragment}$/,'')))

        relative = URI(link)
        absolute = base(options[:content_type]) ? base(options[:content_type]).merge(relative) : options[:resource_url].merge(relative)

        absolute.path = '/' if absolute.path.empty?

        return absolute
      end


      def base(content_type)
        return @base[content_type] if @body_is_parsed.include?(content_type)

        @base[content_type] = nil
        @body_is_parsed << content_type

        b = ContentUrls.base_url(body, content_type)

        return @base[content_type] if b.nil?

        b = URI(b) rescue nil
        @base[content_type] = b unless b.to_s.empty?

        @base[content_type]
      end

    end

    class Link < ActiveRecord::Base
      belongs_to :url
      belongs_to :body
    end

    def initialize(path)
      @path = path

      ActiveRecord::Base.establish_connection(
          :adapter => 'sqlite3',
          :database => (Pathname.new(@path) + 'copy.db').to_s,
          :timeout => 500,
      )
    end

    def create
      Wmonk::CreateDB.migrate(:up)
    end

    def url
      Wmonk::Copy::Url
    end

    def exchange
      Wmonk::Copy::Exchange
    end

    def body
      Wmonk::Copy::Body
    end

    def link
      Wmonk::Copy::Link
    end

    # @return [String] Returns the path to wmonk's working folder for the website
    attr_reader :path

    def add_response(response)
      url = Url.where(url: response.url.to_s).first_or_create!
      response.data.body_digest = Digest::SHA512.base64digest(response.body)
      body = Body.where(digest: response.data.body_digest).first_or_initialize
      body.body = response.body
      body.save!
      exchange = Exchange.where(url: url).first_or_initialize
      exchange.status_code = response.code
      exchange.content_type = response.content_type.to_s
      exchange.content_type.force_encoding('UTF-8') if exchange.content_type.respond_to?(:force_encoding)  # necessary to prevent SQLite3 from occasionally saving as a hex value
      exchange.body = body
      exchange.save!
    end

    def get_body_by_digest(digest)
      Body.find_by(digest: digest)
    end




    # @return [String] Returns the base URL (scheme and hostname) of the website
    attr_reader :xxxbase_url

    # Create an object to represent wmonk's copy of the website
    #
    # @param (String) path the path to wmonk's working forlder for the website
    def xxxinitialize(path)
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
    def xxxresource_count
      rows = 0
      @db.execute( "select count(*) from anemone_storage" ) do |row|
        rows = row[0]
      end
      rows
    end

    # Obtain a resource by its path.
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

    # Obtain a resource by its url.
    #
    # @example
    #   resource = website.resource_by_url('http://www.example.com/index.html')
    # @param [String] url the URL identifying the resource
    # @return [Anemone::Resource] the resource
    def resource_by_url(url)
      rows = @db.execute( "select data from anemone_storage where key=?", url )
      # TODO: error if URL results in multiple resources
      Marshal.load(rows[0][0])  # return first column (the 'data' field) of first row
    end

    # Iterate through all resource records. Block is passed a hash containing record key/value pairs.
    #
    # @example
    #   website.each_resource_record do {|r| puts "URL: #{r[:url]}" }
    def each_resource_record
      rows = @db.execute( "select key, code, content_type, data, is_not_found, is_redirect, redirect_to from anemone_storage")
      rows.each do |r|
        resource_record = {
            :key => r[0],
            :url => r[0],
            :code => r[1],
            :content_type => r[2],
            :data => r[3],
            :resource => Marshal.load(r[3]),
            :is_not_found => r[4] == 0 ? false : true,
            :is_redirect => r[5] == 0 ? false : true,
            :redirect_to => r[6],
        }
        yield(resource_record)
      end
    end

    # Obtain a resource record by its url.
    #
    # @example
    #   resource = website.resource_record_by_url('http://www.example.com/index.html')
    # @param [String] url the URL identifying the resource
    # @return [Hash] the resource's table record containing record key/value pairs
    def resource_record_by_url(url)
      rows = @db.execute( "select key, code, content_type, data, is_not_found, is_redirect, redirect_to from anemone_storage where key=?", url )
      # TODO: error if URL results in multiple resources
      r = rows[0]
      return {
          :key => r[0],
          :url => r[0],
          :code => r[1],
          :content_type => r[2],
          :data => r[3],
          :resource => Marshal.load(r[3]),
          :is_not_found => r[4] == 0 ? false : true,
          :is_redirect => r[5]  == 0 ? false : true,
          :redirect_to => r[6],
      }
    end

  end

end
