require 'rexml/document'
require 'facets/kernel/with'

class Gnip::Activity

  attr_reader :uid,:at,:guid,:type, :publisher

  def initialize(uid, type, at = Time.now, guid = nil, publisher = nil)
    @uid = uid
    @type = type
    if (at.class == Time)
      @at = at.xmlschema
    else
      @at = at unless Time.xmlschema(at).nil?
    end
    @guid = guid
    @publisher = publisher
  end

  def to_xml()
    XmlSimple.xml_out(self.to_hash, {'RootName' => ''})
  end

  def to_hash()
    result = {}
    result['at'] = @at
    result['uid'] = @uid
    result['type'] = @type
    result['guid'] = @guid if @guid
    result['publisher.name'] = @publisher if @publisher
    {'activity' => result }
  end

  def ==(another)
    another.at == at && another.guid == guid && another.type == type && another.uid == uid
  end
  alias eql? ==

  def self.from_hash(hash)
    Gnip::Activity.new(hash['uid'], hash['type'],hash['at'],hash['guid'], hash['publisher.name'])
  end

  def self.from_xml(document)
    hash = XmlSimple.xml_in(document)
    self.from_hash(hash)
  end

  def self.list_to_xml(activity_list)
    activity_list = [] if activity_list.nil?
    return XmlSimple.xml_out(activity_list.collect { |activity| activity.to_hash}, {'RootName' => 'activities', 'AnonymousTag' => nil, 'XmlDeclaration' => Gnip.header_xml})
  end

  def self.unmarshal_activity_xml(activities_xml)
    doc = REXML::Document.new(activities_xml)
    doc.get_elements('/activities/activity').map do |activity_elem|
      Gnip::Activity.new(activity_elem.attribute('uid').value,
                         activity_elem.attribute('type').value,
                         activity_elem.attribute('at').value,
                         activity_elem.attribute('guid').value,
                         activity_elem.attribute('publisher.name').ergo{|a| a.value})
    end
  end

end
