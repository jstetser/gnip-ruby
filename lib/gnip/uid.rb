class Gnip::Uid
  include Comparable

  attr_reader :name, :publisher_name
  def initialize(name, publisher_name)
    @name = name
    @publisher_name = publisher_name;
  end

  def eql?(object)
    self == object
  end

  def ==(object)
    object.instance_of?(self.class) && @name == object.name && @publisher_name == object.publisher_name
  end

  def to_xml()
    XmlSimple.xml_out(self.to_hash, {'RootName' => 'uid', 'XmlDeclaration' => Gnip.header_xml})
  end

  def to_hash
    result = {}
    result['name'] = @name
    result['publisher.name'] = @publisher_name
    result
  end

  def self.from_hash(hash)
    return Gnip::Uid.new(hash['name'], hash['publisher.name'])
  end

  def self.from_xml(document)
    hash = XmlSimple.xml_in(document)
    return self.from_hash(hash)
  end
end
