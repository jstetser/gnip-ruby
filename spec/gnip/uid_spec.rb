require File.dirname(__FILE__) + '/../spec_helper'

describe Gnip::Uid do
  it "should create uid with correct xml format" do
    uid = Gnip::Uid.new('joe', 'twitter')

    uid.to_xml.should == <<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
<uid name="joe" publisher.name="twitter" />
HEREDOC
  end


   it 'should unmarshal from xml correctly' do
    uid_xml =  <<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
<uid name="joe" publisher.name="twitter" />
HEREDOC
    uid = Gnip::Uid.from_xml(uid_xml)
    uid.name.should == 'joe'
    uid.publisher_name.should == 'twitter'
   end
end
