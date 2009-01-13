require 'pp'

module AttrBuilder
  def self.included(base)        #:nodoc:
    base.extend ClassMethods
  end
  
  module ClassMethods
    def attr_builder(*attrs)
      attrs.each do |attribute|       
        attr_accessor attribute
        
        define_method("set_#{attribute}") do |val|
          instance_variable_set("@#{attribute}",val)
          return self
        end
      end
    end
  end    
end
