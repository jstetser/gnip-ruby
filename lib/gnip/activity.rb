class Gnip::Activity
  include Gnip

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
    result['publisher.name'] = @guid if @publisher
    {'activity' => result }
  end

  def self.from_hash(hash)
    Gnip::Activity.new(hash['uid'], hash['type'],hash['at'],hash['guid'], hash['publisher.name'])
  end

  def self.from_xml(document)
    hash = XmlSimple.xml_in(document)
    self.from_hash(hash)
  end
end
