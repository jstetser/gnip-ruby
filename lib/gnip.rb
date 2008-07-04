 require 'base64'
require 'xmlsimple'
require 'net/http'
require 'net/https'
require 'zlib'
require 'time'
require 'logger'
require 'cgi'

module Gnip

  def self.header_xml
    '<?xml version="1.0" encoding="UTF-8"?>'
  end

  def self.five_minute_floor(time)
    Time.at((time.to_f / 300.0).floor * 300.0)
  end

  def self.formatted_time(time)
    time.utc.strftime('%Y%m%d%H%M')
  end

  class Gnip::Base
    def initialize(config)
      @gnip_config = config
    end

    def head(path)
      @gnip_config.logger.debug('Doing HEAD')
      http.get(path,headers)
    end

    def get(path)
      @gnip_config.logger.debug('Doing GET')
      response = http.get2(path, headers)
      if (response.code == '200')
        if (response['Content-Encoding'] == 'gzip')
          @gnip_config.logger.debug("Uncompressing the GET response")
          data = uncompress(response.body)
        else
          data = response.body
        end
      end
      @gnip_config.logger.debug("GET result: #{data}")
      [response, data]
    end

    def post(path, data)
      @gnip_config.logger.debug("POSTing data: #{data}")
      http.post2(path, compress(data), headers)
    end

    def put(path, data)
      @gnip_config.logger.debug("PUTing data: #{data}")
      http.put2(path, compress(data), headers)
    end

    def delete(path)
      @gnip_config.logger.debug("Doing DELETE : #{path}")
      http.delete(path, headers)
    end

    private

    def http
      http = Net::HTTP.new(@gnip_config.base_url, 443)
      http.use_ssl=true
      http.timeout=2
      http.ssl_timeout=2
      http.read_timeout=5
      http
    end

    def headers
      header_hash = {}
      header_hash['Authorization'] = 'Basic ' + Base64::encode64("#{@gnip_config.user}:#{@gnip_config.password}")
      header_hash['Content-Type'] = 'application/xml'
      if @gnip_config.use_gzip
        header_hash['Content-Encoding'] = 'gzip'
        header_hash['Accept-Encoding'] = 'gzip'
      end
      @gnip_config.logger.debug("Gnip Connection Headers: #{header_hash}")
      header_hash
    end

    def compress(data)
      @gnip_config.logger.debug("Gzipping data for request")
      if @gnip_config.use_gzip
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

