class Gnip::Collection

  attr_accessor :post_url
  attr_reader :uids, :name

  def initialize(name)
    @name = name
    @uids = []
  end

  def uri
    'collections'
  end

  def add_uid(uid, publisher_name)
    @uids << Gnip::Uid.new(uid, publisher_name)
  end

  def remove_uid(uid, publisher_name)
    @uids.delete(Gnip::Uid.new(uid, publisher_name))
  end

  def to_xml()
    return XmlSimple.xml_out(self.to_hash, {'RootName' => nil, 'XmlDeclaration' => Gnip.header_xml})
  end

  def to_hash()
    result = {}
    result['name'] = @name
    result['postUrl'] = @post_url if @post_url
    result['uid'] = uids.collect { |uid| uid.to_hash()}
    { 'collection' => result }
  end

  def eql?(object)
    self == object
  end

  def ==(object)
    object.instance_of?(self.class) && @name == object.name
  end

  def self.from_hash(hash)
    collection = new(hash['name'])
    collection.post_url = hash['postUrl'] if hash['postUrl']
    uids = hash['uid']
    if uids
      uids.each do |uid_hash|
        collection.adduid(Gnip::Uid.from_hash(uid_hash))
      end
    end
    return collection
  end

  def self.from_xml(document)
    hash = XmlSimple.xml_in(document)
    return self.from_hash(hash)
  end

  def adduid(uid)
    @uids << uid
  end
end
