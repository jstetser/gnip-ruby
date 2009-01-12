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
    def self.config
      Gnip.connection.config
    end
    
    def config
      self.class.config
    end
    
    def self.connection
      Gnip.connection
    end
    
    def connection
      self.class.connection
    end
    
    def self.logger
      Gnip.logger
    end
     
    def logger
      self.class.logger
    end
    
    def head(path)
        logger.debug('Doing HEAD')
        return http.get(path, headers)
    end

    def get(path)
        logger.debug('Doing GET')
        response = http.get2(path, headers)
        if (response.code == '200')
            if (response['Content-Encoding'] == 'gzip')
                logger.debug("Uncompressing the GET response")
                data = uncompress(response.body)
            else
                data = response.body
            end
        end
        logger.debug("GET result: #{data}")
        return [response, data]
    end
    
    def self.get(path); Gnip::Base.new().get(path); end

    def post(path, data)
        logger.debug("POSTing data: #{data}")
        return http.post2(path, compress(data), headers)
    end
    
    def self.post(path, data); Gnip::Base.new().post(path, data); end

    def put(path, data)
        logger.debug("PUTing data: #{data}")
        return http.put2(path, compress(data), headers)
    end
    
    def self.put(path, data); Gnip::Base.new().put(path, data); end

    def delete(path)
        logger.debug("Doing DELETE : #{path}")
        return http.delete(path, headers)
    end
    
    def self.delete(path); Gnip::Base.new().delete(path); end

    protected

    def http
        hostname, port = config.base_url.split(':')
        port ||= 443

        http = Net::HTTP.new(hostname, port)
        http.read_timeout=config.http_read_timeout
        http.use_ssl = true if port == 443
        return http
    end

    def headers
        header_hash = {}
        header_hash['Authorization'] = 'Basic ' + Base64::encode64("#{config.user}:#{config.password}")
        header_hash['Content-Type'] = 'application/xml'
        header_hash['User-Agent'] = 'Gnip-Client-Ruby/2.0.6'
        if config.use_gzip
            header_hash['Content-Encoding'] = 'gzip'
            header_hash['Accept-Encoding'] = 'gzip'
        end
        logger.debug("Gnip Connection Headers: #{header_hash}")
        header_hash
    end

    def compress(data)
        logger.debug("Gzipping data for request")
        if config.use_gzip
            result = ''
            gzip_writer = Zlib::GzipWriter.new(StringIO.new(result))
            gzip_writer.write(data)
            gzip_writer.close
        else
            result = data
        end
        result
    end

    def uncompress(data)
        Zlib::GzipReader.new(StringIO.new(data)).read
    end
  end

  dir = File.dirname(__FILE__)
  Dir["#{dir}/gnip/*.rb"].each do |file|
    require file
  end
end

