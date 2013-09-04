module Wmonk

  # A folder containing a Wmonk project to copy a website
  class Project

    # Create a new Wmonk project in a folder
    #
    # @param path [String] the path of the folder to contain the project
    # @option options [String] :title title for the project
    # @option options [Array] :root_urls ([]) root URLs for defining scope of spider
    # @option options [Array] :seed_urls ([]) seed URLs for spider to begin
    # @return [Object] the created project
    def self.create(path, options = {})
      options = {
          :title => nil,
          :root_urls => [],
          :seed_urls => [],
      }.merge(options)

      title = { 'title' => options[:title].nil? ? "An untitled Wmonk project" : options[:title] }
      root_urls = { 'root_urls' => options[:root_urls].nil? ? [] : options[:root_urls] }
      seed_urls = { 'seed_urls' => options[:seed_urls].nil? ? [] : options[:seed_urls] }

      # create working folder if it does not exist
      Dir.mkdir path if ! File.exists? path
      raise "path is not a folder - #{path}" if ! File.directory? path

      # error if working folder is not empty
      if ! (Dir.entries(path) - %w{ . .. }).empty?
        raise "cannot initialize non-empty project folder - #{path}"
      end

      conf_filename = Pathname.new(path) + CONF_FILENAME
      conf = ERB.new(File.open(Wmonk.assets_path(CONF_TEMPLATE), 'r').read).result binding
      File.open(conf_filename, 'w') { |f| f.write(conf) }

      open(path)
    end

    # Open an existing Wmonk project from a folder
    #
    # @param path [String] the path of the folder containing the project
    # @return [Object] the opened project
    def self.open(path)
      conf_filename = Pathname.new(path) + CONF_FILENAME
      conf = YAML::load(File.open(conf_filename, 'r'))
      raise "problem with project configuration file - #{conf_filename}" if conf.nil?
      new(path, conf)
    end

    # The project's title
    # @return [String]
    def title
      @conf['title']
    end

    # The project's root URLs
    # @return [Array]
    def root_urls
      @conf['root_urls']
    end

    def url_in_scope?(url)
      url = URI.parse(url.to_s)
      root_urls.each do |r|
        r = URI.parse(r)
        return true if url.host == r.host and url.scheme == r.scheme and url.port == r.port
      end
      return false
    end

    # The project's seed URLs
    # @return [Array]
    def seed_urls
      @conf['seed_urls']
    end

    attr_reader :path

    protected
    def initialize(path, conf)
      @path = path
      @conf = conf
    end

  end

end
