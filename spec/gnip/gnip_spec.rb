require File.dirname(__FILE__) + '/../spec_helper'

describe Gnip do
  describe 'time' do
    it "should should floor gmt time properly" do
      server_time = "Tue, 15 Jan 2008 14:08:00 GMT"
      last_poll_time = Time.httpdate(server_time)
      Gnip.five_minute_floor(last_poll_time).should == Time.parse("Tue Jan 15 14:05:00 UTC 2008")

      server_time = "Tue, 10 Jun 2008 14:08:00 GMT"
      last_poll_time = Time.httpdate(server_time)
      Gnip.five_minute_floor(last_poll_time).should == Time.parse("Tue Jun 10 14:05:00 UTC 2008")
    end

    it "should format time to gnip time" do
      server_time = "Tue, 15 Jan 2008 14:08:00 GMT"
      last_poll_time = Time.httpdate(server_time)
      Gnip.formatted_time(last_poll_time).should == "200801151408"
    end
  end
end