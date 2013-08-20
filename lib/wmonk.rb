require 'wmonk/version.rb'

require 'pathname'
require 'uri'
require 'cgi'
require 'logger'
require 'sqlite3'
require 'anemone'
require 'webrick'
require 'rack'
require 'yaml'
require 'sinatra/base'
require 'slim'

require 'wmonk/project'
require 'wmonk/anemone_storage_sq_lite3'
require 'wmonk/copy'
require 'wmonk/info_server'
require 'wmonk/web_server'

module Wmonk

  CONF_FILENAME = 'wmonk.yaml'
  CONF_TEMPLATE = 'wmonk.yaml.template'
  SUPPORTED_URI_SCHEMES = ['http', 'https']
  WELL_KNOWN_FILES_FILENAME = 'well_known_files.yaml'

  def assets_path(filename = nil)
    path = File.join(File.dirname(__FILE__), '../assets/')
    path = path + filename if ! filename.nil?
    path
  end

  # List of well known files often found on websites
  # @return [Array] the list of well known files
  def well_known_files
    @@well_known_files ||= nil
    if @@well_known_files.nil?
      @@well_known_files = []
      YAML::load(File.open(assets_path(WELL_KNOWN_FILES_FILENAME)), 'r').each {|f| @@well_known_files << f}
    end
    @@well_known_files
  end

end
