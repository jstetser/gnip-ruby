class Gnip::Rule
  include Comparable

  attr_reader :type, :value
  def initialize(type, value)
    @type = type
    @value = value;
  end

  def eql?(object)
    self == object
  end

  def ==(object)
    object.instance_of?(self.class) && @type == object.type && @value == object.value
  end

  def to_xml()
    XmlSimple.xml_out(self.to_hash, {'RootName' => 'rule', 'XmlDeclaration' => Gnip.header_xml})
  end

  def to_hash
    result = {}
    result['type'] = @type
    result['value'] = @value
    result
  end

  def self.from_hash(hash)
    return Gnip::Rule.new(hash['type'], hash['value'])
  end

  def self.from_xml(document)
    hash = XmlSimple.xml_in(document)
    return self.from_hash(hash)
  end
end
