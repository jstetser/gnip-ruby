require File.dirname(__FILE__) + '/../spec_helper'

describe Gnip::Payload do
    it 'should gzip and base64 encode raw' do
        payload = Gnip::Payload.new("raw", "body")
        payload.body.should == 'body'
        Gnip::Payload.decode(payload.raw_value).should == "raw"
    end

    it "should unencode and unzip raw" do
        payload = Gnip::Payload.new("raw", "body")
        payload.body.should == 'body'
        payload.raw.should == 'raw'
    end

    it "should allow body to be optional" do
        payload = Gnip::Payload.new("raw")
        payload.raw.should == 'raw'
        payload.body.should be_nil
    end

end