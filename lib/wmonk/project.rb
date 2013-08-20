module Wmonk

  # A folder containing a Wmonk project to copy a website
  class Project
    extend Wmonk

    # Create a new Wmonk project in a folder
    #
    # @param path [String] the path of the folder to contain the project
    # @option options [String] :title title for the project
    # @option options [Array] :seed_urls ([]) seed URLs for spider
    # @option options [Boolean] :seed_well_known_files (false) whether to include seed URLs for well known files
    # @return [Object] the created project
    def self.create(path, options = {})
      options = {
          :title => nil,
          :seed_urls => [],
          :seed_well_known_files => false,
      }.merge(options)

      # build list of seed URLs
      seed_urls = []
      host = port = scheme = nil
      options[:seed_urls].each do |u|
        seed_urls << u
        warn "bad seed URL: #{u}" && next if u !~ URI::DEFAULT_PARSER.regexp[:ABS_URI]
        u = URI.parse u
        u.scheme = u.scheme.downcase
        warn "#{u.scheme} scheme not supported - #{u}" && next if ! SUPPORTED_URI_SCHEMES.include? u.scheme
        u.host = u.host.downcase
        if host.nil?  # first URL is used to to determine default host, port, scheme
          host = u.host
          port = u.port
          scheme = u.scheme
          if options[:seed_well_known_files]
            well_known_files.each { |path| seed_urls << URI.parse("#{scheme}://#{host}:#{port}#{path}").to_s }
          end
        elsif host != u.host or port != u.port or scheme != u.scheme
          warn "multiple websites not supported - #{seed_urls[0]} and #{u}"
        end
      end

      title = { 'title' => options[:title] }
      if options[:title].nil?
        if host.nil? && seed_urls.size == 0
          title = { 'title' => "Wmonk project to copy an unspecified website" }
        else
          title = { 'title' => "Wmonk project to copy " + (host.nil? ? seed_urls[0] : URI.parse("#{scheme}://#{host}:#{port}").to_s) }
        end
      end

      # create working folder if it does not exist
      Dir.mkdir path if ! File.exists? path
      raise "path is not a folder - #{path}" if ! File.directory? path

      # error if working folder is not empty
      if ! (Dir.entries(path) - %w{ . .. }).empty?
        raise "cannot initialize non-empty project folder - #{path}"
      end

      conf_filename = Pathname.new(path) + CONF_FILENAME
      seed_urls = { 'seed_urls' => seed_urls }
      conf = ERB.new(File.open(assets_path(CONF_TEMPLATE), 'r').read).result binding
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

    # The project's seed URLs
    # @return [Array]
    def seed_urls
      @conf['seed_urls']
    end

    protected
    def initialize(path, conf)
      @path = path
      @conf = conf
    end

  end

end
