require File.dirname(__FILE__) + '/../spec_helper'

describe Gnip::Publisher do

  it 'should unmarshal from xml correctly' do
    publisher_xml =  <<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
  <publisher name="url-safe-name" />
HEREDOC
    publisher = Gnip::Publisher.from_xml(publisher_xml)
    publisher.name.should == "url-safe-name"
  end

  it 'should unmarshal from xml list correctly' do
    publishers_xml =  <<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
  <publishers>
    <publisher name="url-safe-name1" />
    <publisher name="url-safe-name2" />
  </publishers>
HEREDOC
    publishers_list = XmlSimple.xml_in(publishers_xml)
    publishers =  publishers_list['publisher'].collect { |publisher_hash| Gnip::Publisher.from_hash(publisher_hash)}
    publishers[0].name.should == "url-safe-name1"
    publishers[1].name.should == "url-safe-name2"
   end

  it 'should marshal to xml correctly' do
    publisher = Gnip::Publisher.new('url-safe-name')
    publisher.to_xml.should ==  <<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
  <publisher name="url-safe-name" />
HEREDOC
  end

  it 'should be equal if names are equal' do
    publisher1 = Gnip::Publisher.new('url-safe-name')
    publisher2 = Gnip::Publisher.new('url-safe-name')
    publisher1.should == publisher2
  end
end