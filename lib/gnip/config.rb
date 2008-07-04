dir = File.dirname('__FILE__')

class Gnip::Config
  attr_reader :base_url, :user, :password, :use_gzip
  attr_accessor :logger

  def initialize(user, password, gnip_server='s.gnipcentral.com', use_gzip = true)
    @base_url = gnip_server
    @user = user
    @password = password
    @use_gzip = use_gzip
    @logger = Logger.new(STDERR)
    @logger.level = Logger::ERROR
  end
end