require 'pathname'
require Pathname(__FILE__).dirname + 'spec_helper'

describe Gnip do
  describe '.logger' do
    it 'should provide a logger even before a connection is established' do
      Gnip.logger.should be_instance_of(Logger)
    end 
  end

end 
