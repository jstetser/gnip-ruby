class Time
  def to_gnip_bucket_id 
    containing_bucket_start = Time.at(to_i.div(60) * 60)
    containing_bucket_start.utc.strftime('%Y%m%d%H%M')
  end
end
