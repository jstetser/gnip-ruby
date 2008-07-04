require File.dirname(__FILE__) + '/../spec_helper'

describe Gnip::Connection do

  before do
    @mock_publisher_name = 'mock_pub'
    @mock_collection_name = 'mock_collection'
    @mock_publisher = Gnip::Publisher.new(@mock_publisher_name)
    @mock_collection = Gnip::Collection.new(@mock_collection_name)

    @server_now = Time.now.utc
    @activities = pub_activities
    @gnip_config = Gnip::Config.new("user", "password", "s.gnipcentral.com", false)
    @gnip_connection = Gnip::Connection.new(@gnip_config)
  end

  describe "ActivityStream" do

    describe "For Subscriber" do
      it "should get activities per publisher for a given time" do
        setup_mock_for_publisher( @activities, @server_now)
        response, activities = @gnip_connection.activities_stream(@mock_publisher, @server_now)
        response.code.should == '200'
        Gnip::Connection.send(:list_to_xml, activities).should == @activities
      end

      it "should get current activites  per publisher " do
        setup_mock_for_publisher(@activities)
        response, activities = @gnip_connection.activities_stream(@mock_publisher)
        response.code.should == '200'
        Gnip::Connection.send(:list_to_xml, activities).should == @activities
      end

      it "should get activities per collection for a given time" do
        setup_mock_for_collection(@activities, @server_now)
        response, activities = @gnip_connection.activities_stream(@mock_collection, @server_now)
        response.code.should == '200'
        Gnip::Connection.send(:list_to_xml, activities).should == @activities
      end

      it "should get current activites per collection" do
        setup_mock_for_collection(@activities)
        response, activities = @gnip_connection.activities_stream(@mock_collection)
        response.code.should == '200'
        Gnip::Connection.send(:list_to_xml, activities).should == @activities
      end
    end

    describe "For Publisher" do
      it "should post activities as xml successfully" do
        setup_mock_for_publishing(@activities)
        response = @gnip_connection.publish_xml(@mock_publisher, @activities)
        response.code.should == "200"
      end

      it "should post activities as list successfully" do
        now = Time.now
        activity_list = []
        activity_list << Gnip::Activity.new("joe", "added_friend", now, "qwerty890")
        activity_list << Gnip::Activity.new("jane", "added_application", now, "def456")
        setup_mock_for_publishing(pub_activities_at(now))
        response = @gnip_connection.publish(@mock_publisher, activity_list)
        response.code.should == "200"
      end
    end

    it 'should marshall to a list correctly' do
      now = Time.now
      activity_xml =  pub_activities_at(now)
      activity_list = Gnip::Connection.send(:list_from_xml, activity_xml)
      activity = activity_list[0]
      activity.at.should == now.xmlschema
      activity.uid.should == 'joe'
      activity.type.should == 'added_friend'
      activity.guid.should == 'qwerty890'
      activity = activity_list[1]
      activity.at.should == now.xmlschema
      activity.uid.should == 'jane'
      activity.type.should == 'added_application'
      activity.guid.should == 'def456'
    end

    it 'should marshall from a list correctly' do
      now = Time.now
      activity_list = []
      activity_list << Gnip::Activity.new("joe", "added_friend", now, "qwerty890")
      activity_list << Gnip::Activity.new("jane", "added_application", now, "def456")
      activity_xml =  pub_activities_at(now)
      Gnip::Connection.send(:list_to_xml, activity_list).should == activity_xml
    end
  end

  describe "Collection" do
    it "should create a new collection for given collection xml" do
      collection = Gnip::Collection.new('new-collection')
      setup_mock_for_collection_create(collection)
      response = @gnip_connection.create(collection)
      response.code.should == "200"
    end

    it "should find a collection for given name" do
      collection_name = 'some-existing-collection'
      setup_mock_for_collection_find(collection_name)
      response, collection = @gnip_connection.get_collection(collection_name)
      response.code.should == "200"
      collection.name.should == 'some-existing-collection'
    end

    it "should update a collection for given collection" do
      collection = Gnip::Collection.new('existing-collection')
      setup_mock_for_collection_update(collection)
      response = @gnip_connection.update(collection)
      response.code.should == "200"
    end

    it 'should add a uid to the given collection' do
      collection = Gnip::Collection.new('existing-collection')
      uid = Gnip::Uid.new('testUid', @mock_publisher_name)
      setup_mock_for_add_uid(collection, uid)
      response = @gnip_connection.addUid(collection, uid)
      response.code.should == "200"
    end

    it 'should remove a uid from the given collection' do
      collection = Gnip::Collection.new('existing-collection')
      uid = Gnip::Uid.new('testUid', @mock_publisher_name)
      setup_mock_for_delete_uid(collection, uid)
      response = @gnip_connection.removeUid(collection, uid)
      response.code.should == "200"
    end

    it "should delete a collection for given collection" do
      collection = Gnip::Collection.new('existing-collection')
      setup_mock_for_collection_delete(collection)
      response = @gnip_connection.remove(collection)
      response.code.should == "200"
    end
  end

  describe "Publisher" do

    it "should create a new publisher" do
      publisher = Gnip::Publisher.new('new-publisher')
      setup_mock_for_publisher_create(publisher)
      response = @gnip_connection.create(publisher)
      response.code.should == "200"
    end

    it "should return a  publisher for given publisher name" do
      publisher_name = 'existing-publsher'
      setup_mock_for_publisher_get(publisher_name)
      response, publisher = @gnip_connection.get_publisher(publisher_name)
      response.code.should == "200"
      publisher.name.should == publisher_name
    end
  end

  describe "Publihsers" do
    it 'should list existing publishers' do
      setup_mock_for_publishers_get([@mock_publisher])
      response, publishers = @gnip_connection.get_publishers
      response.code.should == "200"
      publishers.include?(@mock_publisher).should be_true
    end
  end

  private

  def mock_http
    a_mock = mock('http_mock')
    Net::HTTP.should_receive(:new).with(@gnip_config.base_url, 443).and_return(a_mock)
    a_mock.should_receive(:use_ssl=).with(true)
    a_mock.should_receive(:timeout=).with(2)
    a_mock.should_receive(:ssl_timeout=).with(2)
    a_mock.should_receive(:read_timeout=).with(5)
    a_mock
  end

  def headers
    @gnip_connection.send(:headers)
  end

  def successful_response
    response = mock('response')
    response.should_receive(:code).with(no_args).any_number_of_times.and_return("200")
    response.should_receive(:[]).with('Content-Encoding').any_number_of_times.and_return('')
    response
  end

  def setup_mock_for_publishers_get(expected_publishers)
    mock_response = successful_response
    mock_response.should_receive(:body).with(no_args).and_return(list_to_xml(expected_publishers, 'publishers'))
    mock_http.should_receive(:get2).with("/publishers.xml", headers).and_return(mock_response)
  end

  def setup_mock_for_publisher_get(expected_publisher_name)
    mock_response = successful_response
    mock_response.should_receive(:body).with(no_args).and_return(Gnip::Publisher.new(expected_publisher_name).to_xml)
    mock_http.should_receive(:get2).with("/publishers/#{expected_publisher_name}.xml", headers).and_return(mock_response)
  end

  def setup_mock_for_publisher_create(expected_publisher)
    mock_http.should_receive(:post2).with("/publishers", expected_publisher.to_xml, headers).and_return(successful_response)
  end

  def setup_mock_for_collection_create(expected_collection)
    mock_http.should_receive(:post2).with("/collections", expected_collection.to_xml, headers).and_return(successful_response)
  end

  def setup_mock_for_add_uid(collection, uid)
    mock_http.should_receive(:post2).with("/collections/#{collection.name}/uids", uid.to_xml, headers).and_return(successful_response)
  end

  def setup_mock_for_delete_uid(collection, uid)
    mock_http.should_receive(:delete).with("/collections/#{collection.name}/uids?uid=#{uid.name}&publisher.name=#{uid.publisher_name}", headers).and_return(successful_response)
  end

  def setup_mock_for_collection_update(expected_collection)
    mock_http.should_receive(:put2).with("/collections/#{expected_collection.name}.xml", expected_collection.to_xml, headers).and_return(successful_response)
  end

  def setup_mock_for_collection_delete(expected_collection)
    mock_http.should_receive(:delete).with("/collections/#{expected_collection.name}.xml", headers).and_return(successful_response)
  end

  def setup_mock_for_collection_find(expected_collection_name)
    mock_response = successful_response
    mock_response.should_receive(:body).with(no_args).and_return(Gnip::Collection.new(expected_collection_name).to_xml)
    mock_http.should_receive(:get2).with("/collections/#{expected_collection_name}.xml", headers).and_return(mock_response)
  end

  def setup_mock_for_publishing(activities_xml)
    mock_http.should_receive(:post2).with("/publishers/#{@mock_publisher_name}/activity", activities_xml, headers).and_return(successful_response)
  end

  def setup_mock_for_publisher(activities, server_time = nil)
    prefix_path = "/publishers/#{@mock_publisher_name}"
    setup_mock_for_activity_get(activities, prefix_path, server_time)
  end

  def setup_mock_for_activity_get(activities, prefix_path, server_time = nil)
    headers = @gnip_connection.send(:headers)
    if (server_time)
      time = Gnip.five_minute_floor(server_time)
      formatted_time = Gnip.formatted_time(time)
      path = "#{prefix_path}/activity/#{formatted_time}.xml"
    else
      path = "#{prefix_path}/activity/current.xml"
    end
    mock_response = successful_response
    mock_response.should_receive(:body).and_return(activities)
    mock_http.should_receive(:get2).with(path, headers).and_return(mock_response)
  end

  def setup_mock_for_collection(activities, server_time = nil)
    prefix_path = "/collections/#{@mock_collection_name}"
    setup_mock_for_activity_get(activities, prefix_path, server_time)
  end

  def pub_activities_at(time)
    str = <<-HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
<activities>
    <activity guid="qwerty890" type="added_friend" uid="joe" at="#{time.xmlschema}" />
    <activity guid="def456" type="added_application" uid="jane" at="#{time.xmlschema}" />
</activities>
    HEREDOC
    str
  end

  def pub_activities
    str = <<-HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
<activities>
    <activity guid="qwerty890" type="added_friend" uid="joe" at="2007-05-23T00:53:11+01:00" />
    <activity guid="def456" type="added_application" uid="jane" at="2008-05-23T00:52:11+04:00" />
</activities>
    HEREDOC
    str
  end

  def list_to_xml(list, root_name)
    list = [] if list.nil?
    return XmlSimple.xml_out(list.collect { |item| item.to_hash}, {'RootName' => root_name, 'AnonymousTag' => nil, 'XmlDeclaration' => Gnip.header_xml})
  end
end