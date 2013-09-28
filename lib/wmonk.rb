require 'wmonk/version.rb'

require 'pathname'
require 'uri'
#require 'addressable/uri'
require 'cgi'
require 'logger'
require 'sqlite3'
require 'anemone'
require 'content_urls'
require 'webrick'
require 'rack'
require 'yaml'
require 'sinatra/base'
require 'slim'

require 'wmonk/project'
require 'wmonk/copy'
require 'wmonk/anemone_storage'
require 'wmonk/server'


module Wmonk

  CONF_FILENAME = 'wmonk.yaml'
  CONF_TEMPLATE = 'wmonk.yaml.template'
  SUPPORTED_URI_SCHEMES = ['http', 'https']
  WELL_KNOWN_FILES_FILENAME = 'well_known_files.yaml'

  def self.assets_path(filename = nil)
    path = File.join(File.dirname(__FILE__), '../assets/')
    path = path + filename if ! filename.nil?
    path
  end

  # List of well known files often found on websites
  # @return [Array] the list of well known files
  def self.well_known_files
    @@well_known_files ||= nil
    if @@well_known_files.nil?
      @@well_known_files = []
      YAML::load(File.open(assets_path(WELL_KNOWN_FILES_FILENAME)), 'r').each {|f| @@well_known_files << f}
    end
    @@well_known_files
  end

  # List of root URLs for a list of URLs
  # @option options [Array] :urls ([]) list of URLs
  # @return [Array] the list of root URLs for the supplied list URLs
  def self.root_urls(urls)
    urls ||= []
    root_urls = []
    urls.each do |url|
      url = URI.parse(url)
      url.path = '/'
      url.query = nil
      url.fragment = nil
      root_urls << url.to_s
    end
    root_urls.uniq
  end

end
