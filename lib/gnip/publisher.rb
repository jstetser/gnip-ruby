class Gnip::Publisher
  attr_reader :name
  attr_accessor :supported_rule_types

  def initialize(name, suppported_rule_types = [])
    @name = name
    @supported_rule_types = suppported_rule_types
  end

  def uri
    'publishers'
  end

  def to_xml()
    return XmlSimple.xml_out(self.to_hash, {'RootName' => nil, 'XmlDeclaration' => Gnip.header_xml})
  end

  def to_hash()
    result = {}
    result['name'] = @name
    result['supportedRuleTypes'] = @supported_rule_types.collect { |type| type.to_hash}
    { 'publisher' => result }
  end

  def ==(object)
    object.instance_of?(self.class) && @name == object.name
  end
  alias :eql? :==

  def self.from_hash(hash)       
      found_rule_types = []
      rule_types = hash['supportedRuleTypes']
        if rule_types
            rule_types.each do |rule_type_hash|                
                found_rule_types << Gnip::RuleType.from_hash(rule_type_hash['type'].first)
            end
        end
    return Gnip::Publisher.new(hash['name'], found_rule_types)
  end

  def self.from_xml(document)
    hash = XmlSimple.xml_in(document)
    return self.from_hash(hash)
  end

  private

  def path
    "/publishers/#{name}/activity"
  end
end
