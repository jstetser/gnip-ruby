require 'facets/kernel/ergo'

class Time
  def to_gnip_bucket_id 
    Time.at(to_i.div(300) * 300).ergo do |containing_bucket_start|
      containing_bucket_start.utc.strftime('%Y%m%d%H%M')
    end
  end
end
