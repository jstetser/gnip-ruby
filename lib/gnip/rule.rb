class Gnip::Rule < Gnip::Base
  include Comparable

  attr_reader :type, :value
  def initialize(type, value)
    @type = type
    @value = value;
  end
  
  def self.exists?(publisher, filter, rule)
    true if find(publisher, filter, rule)
  end
  
  def self.find(publisher, filter, rule)
    logger.info("Finding rule matching (#{rule.type}:#{rule.value}) on #{filter.class} for publisher #{publisher.name}")
    res, data = get( uri(publisher, filter, rule) )
    return Gnip::Rule.from_xml(data) if res.code == "200"
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
  
  def self.to_params
    "?type=#{self.type}&value=#{self.value}"
  end

  def self.from_hash(hash)
    return Gnip::Rule.new(hash['type'], hash['value'])
  end

  def self.from_xml(document)
    hash = XmlSimple.xml_in(document)
    return self.from_hash(hash)
  end
  
  def self.uri(publisher, filter, rule)
    if rule
      ext = '.xml'
      params = "?type=#{rule.type}&value=#{rule.value}"
    end
    path = "#{self.prefix(publisher, filter)}#{ext || ''}#{params || ''}"
  end
  
  def uri(publisher, filter, options = {})
    ext = options.delete(:extension)
    if ext.nil? or ext.to_s == ''
      ext = ''
    else
      ext = ".#{ext.to_s}"
    end
    
    params = (options.delete(:specific) ? self.to_params : '')
    path = "#{self.prefix(publisher, filter)}#{ext}#{params}"
  end

  def self.prefix(publisher, filter)
    "#{filter.prefix(publisher)}/rules"
  end
    
  def prefix(publisher, filter)
    self.class.prefix(publisher, filter)
  end
end
