require File.dirname(__FILE__) + '/../spec_helper'

describe Gnip::Collection do
  it "should create collection with correct xml format" do
    collection = Gnip::Collection.new('url-safe-name')
    collection.add_uid("joe", "twitter")
    collection.add_uid("jack", "digg")

    collection.to_xml.should == <<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
  <collection name="url-safe-name">
    <uid name="joe" publisher.name="twitter" />
    <uid name="jack" publisher.name="digg" />
  </collection>
HEREDOC

  end

  it "should create collection with correct xml format with POST URL" do
    collection = Gnip::Collection.new('url-safe-name')
    collection.post_url = "http://example.com"
    collection.add_uid("joe", "twitter")
    collection.add_uid("jack", "digg")

    collection.to_xml.should == <<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
  <collection name="url-safe-name" postUrl="http://example.com">
    <uid name="joe" publisher.name="twitter" />
    <uid name="jack" publisher.name="digg" />
  </collection>
HEREDOC
  end

   it 'should unmarshal from xml correctly' do
    collection_xml =  <<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
  <collection name="url-safe-name">
    <uid name="joe" publisher.name="twitter" />
    <uid name="jack" publisher.name="digg" />
  </collection>
HEREDOC
    collection = Gnip::Collection.from_xml(collection_xml)
    collection.name.should == "url-safe-name"
    collection.uids.size.should == 2
    collection.uids[0].name.should == 'joe'
    collection.uids[0].publisher_name.should == 'twitter'
    collection.post_url.should be_nil
   end

  it 'should unmarshal from xml correctly without uids' do
    collection_xml =  <<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
  <collection name="url-safe-name">
  </collection>
HEREDOC
    collection = Gnip::Collection.from_xml(collection_xml)
    collection.name.should == "url-safe-name"
    collection.uids.size.should == 0
    collection.post_url.should be_nil
  end

  it 'should unmarshal from xml correctly with POST URL' do
    collection_xml =  <<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
  <collection name="url-safe-name" postUrl="http://example.com">
    <uid name="joe" publisher.name="twitter" />
    <uid name="jack" publisher.name="digg" />
  </collection>
HEREDOC
    collection = Gnip::Collection.from_xml(collection_xml)
    collection.name.should == "url-safe-name"
    collection.uids.size.should == 2
    collection.uids[0].name.should == 'joe'
    collection.uids[0].publisher_name.should == 'twitter'
    collection.post_url.should == "http://example.com"
  end

  it "should allow adding and removing uids" do
    collection = Gnip::Collection.new('url-safe-name')
    collection.add_uid('joe','twitter')
    collection.add_uid("jack", "digg")
    collection.uids.size.should == 2
    collection.remove_uid("jack", "digg")
    collection.uids.size.should == 1
  end
end
