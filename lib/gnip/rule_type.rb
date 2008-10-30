class Gnip::RuleType
  include Comparable

  attr_reader :value
  def initialize(value)
    @value = value;
  end

  def eql?(object)
    self == object
  end

  def ==(object)
    object.instance_of?(self.class) && @value == object.value
  end

  def to_xml()
    XmlSimple.xml_out(self.to_hash, {'RootName' => '', 'XmlDeclaration' => Gnip.header_xml})
  end

  def to_hash
    result = {}
    result['type'] = [@value]
    result
  end

  def self.from_hash(hash)
    return Gnip::RuleType.new(hash)
  end

  def self.from_xml(document)
    hash = XmlSimple.xml_in(document)
    return self.from_hash(hash)
  end
end
