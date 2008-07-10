require 'rubygems'
require 'base64'
require 'xmlsimple'
require 'net/http'
require 'net/https'
require 'zlib'
require 'time'
require 'logger'
require 'cgi'
require 'facets/kernel/returning'

class Gnip
  class << self
    attr_accessor :connection

    # Initialize this library's connection to Gnip.
    #
    # @param [String] user_name   The Gnip username that should be used
    #                             when communicating with the server.  
    # @param [String] password    The password of the Gnip user.
    # @param [String] gnip_server The name of the Gnip server to use.  
    #                             Default: 's.gnipcentral.com'
    def connect(user_name, password, gnip_server = 's.gnipcentral.com')
      reset_connection
      Connection.new(@config = Config.new(user_name, password, gnip_server, true))
    end
    
    # Resets (forgets) the canonical connection to Gnip.
    def reset_connection
      @connection = nil
    end

    # @return [Logger]   The logger that is used by this library.
    def logger    
      if connection
        connection.config.logger
      else
        # Fake a logger up so that we can muddle through until we are
        # configure properly.
        returning(Logger.new(STDERR)) {|l| l.level = Logger::INFO}
      end
    end
    
    # Registers a new connection with the Gnip library.  This method is not for public use.
    # 
    # @private
    #
    # ---
    #
    # This exists as a way to provide a backwards compatible interface
    # for connections.  Connection register themselves whenever they
    # are created and the first one to register becomes the canonical
    # connection.  Hopefully it will go away at some point.
    def register_connection(connection)
      @connection = connection unless @connection
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

