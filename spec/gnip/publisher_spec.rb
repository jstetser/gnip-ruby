require File.dirname(__FILE__) + '/../spec_helper'

describe Gnip::Publisher do
  describe '#publish(activities)' do
    before do
      @response = stub('mock response', :code => '200')
    end

    it 'should post activities XML' do
      Gnip.connection.should_receive(:post).with(anything,<<ACTIVITYXML).and_return(@response)
<?xml version="1.0" encoding="UTF-8"?>
<activities>
    <activity guid="qwerty890" type="added_friend" uid="joe" at="2007-05-23T00:53:11Z" />
    <activity guid="def456" type="added_application" uid="jane" at="2008-08-23T00:53:11Z" />
</activities>
ACTIVITYXML

      Gnip::Publisher.new('foo').publish([Gnip::Activity.new("joe", "added_friend", Time.parse('2007-05-23T00:53:11Z'), "qwerty890"),
                                          Gnip::Activity.new("jane", "added_application", Time.parse('2008-08-23T00:53:11Z'), "def456")])
    end 

    it 'should post using the canonical connection' do
      Gnip.connection.should_receive(:post).and_return(@response)

      Gnip::Publisher.new('foo').publish([])
    end 

    it 'should post to the activities URL for the publisher' do
      Gnip.connection.should_receive(:post).with('/publishers/foo/activity', anything).and_return(@response)

      Gnip::Publisher.new('foo').publish([])
    end 

  end 

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
