require File.dirname(__FILE__) + '/../spec_helper'
require 'ext/time'

describe Time, '#to_gnip_bucket_id' do
  it 'should return the %Y%m%d%H%M of the previous 5 minute boundary from middle of period' do
    Time.parse("2008-07-09T10:00:10Z").to_gnip_bucket_id.should == '200807091000'
  end 

  it 'should return the %Y%m%d%H%M of the previous 5 minute boundary from early in period' do
    Time.parse("2008-07-09T10:02:30Z").to_gnip_bucket_id.should == '200807091000'
  end 

  it 'should return the %Y%m%d%H%M of the previous 5 minute boundary from late in period' do
    Time.parse("2008-07-09T10:04:50Z").to_gnip_bucket_id.should == '200807091000'
  end 

  it 'should transform local times into UTC ' do
    Time.parse("2008-07-09T10:02-0500").to_gnip_bucket_id.should == '200807091500'  
  end 
end
