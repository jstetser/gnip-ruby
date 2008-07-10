require 'pathname'
require Pathname(__FILE__).dirname + 'spec_helper'

describe Gnip do
  describe '.connect' do
    it 'should establish a global connection to gnip' do
      Gnip.connect("user@domain.example", "hello")
      
      Gnip.connection.should be_instance_of(Gnip::Connection)
    end 

    it 'should replace current global connection if called a second time' do
      Gnip.connect("user@domain.example", "hello")
      old_conn = Gnip.connection

      Gnip.connect("user@domain.example", "hello")
      Gnip.connection.should_not equal(old_conn)
    end 
  end

  describe '.reset_connection' do 
    it 'should set conection to nil' do
      Gnip.connect("account@domain.example", "pasword")
      Gnip.reset_connection
      Gnip.connection.should be_nil
    end 
  end

  describe '.logger' do 
    it 'should provide a logger even before a connection is established' do
      Gnip.reset_connection
      Gnip.logger.should be_instance_of(Logger)
    end 
  end

end 
