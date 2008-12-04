require 'rubygems'
require 'base64'
require 'xmlsimple'
require 'net/http'
require 'net/https'
require 'zlib'
require 'time'
require 'logger'
require 'cgi'
require 'pathname'
require Pathname(__FILE__).dirname + 'ext/time'

class Gnip
  class << self
    attr_accessor :connection

    # @return [Logger]   The logger that is used by this library.
    def logger    
      if connection
        connection.config.logger
      else
        # Fake a logger up so that we can muddle through until we are configured properly.
        l = Logger.new(STDERR)
        l.level = Logger::INFO
        return l
      end
    end
  end

  def self.header_xml
    '<?xml version="1.0" encoding="UTF-8"?>'
  end

  class Gnip::Base
  end

  dir = File.dirname(__FILE__)
  Dir["#{dir}/gnip/*.rb"].each do |file|
    require file
  end
end

