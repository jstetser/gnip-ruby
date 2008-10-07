class Gnip::Config
  attr_reader :base_url, :user, :password, :use_gzip
  attr_accessor :logger, :http_read_timeout

  def initialize(user, password, gnip_server='prod.gnipcentral.com', use_gzip = true, http_read_timeout = 5)
    @base_url = gnip_server
    @user = user
    @password = password
    @use_gzip = use_gzip
    @logger = Logger.new(STDERR)
    @logger.level = Logger::ERROR
    @http_read_timeout = http_read_timeout
  end
end