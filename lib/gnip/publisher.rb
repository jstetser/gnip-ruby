class Gnip::Publisher
  attr_reader :name
  attr_accessor :supported_rule_types
  attr_accessor :scope

  def initialize(name, suppported_rule_types = [], scope = 'my')
    @name = name
    @scope = scope
    @supported_rule_types = suppported_rule_types
  end

  def uri
    "/#{@scope}/publishers/#{@name}"
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

  def self.from_hash(hash, scope = 'my')
      found_rule_types = []
      rule_types = hash['supportedRuleTypes']
        if rule_types
            rule_types.each do |rule_type_hash|                
                found_rule_types << Gnip::RuleType.from_hash(rule_type_hash['type'].first)
            end
        end
    return Gnip::Publisher.new(hash['name'], found_rule_types, scope)
  end

  def self.from_xml(document, scope = 'my')
    hash = XmlSimple.xml_in(document)
    return self.from_hash(hash, scope)
  end

  private

  def path
    "/my/publishers/#{name}/activity"
  end
end
