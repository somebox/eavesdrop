 $:.unshift(File.dirname(__FILE__)) unless
   $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
=begin

Eavesdrop was designed to capture network traffic (by messing with TCPSocket) and allow the conversation to be recorded, to a file for instance. It also allows these conversations to be replayed. The goal is to allow for a suite of tests that work against "real" network resources, but are repeatable and easier to maintain.

Example:

Using it in tests

  # feed_test.rb:

  def test_something_network_related
    eavesdrop('network_test_1') do 
      Feed.update_news_from('http://news.google.com')
      assert_equal 'NSA Admits Wrongdoing', Feed.top_story.title
    end
  end

Record the results
  
  $ EAVESDROP=1 ruby test/feed_test.rb
  ... tests run

Results saved as YAML
  
  $ cat test/fixtures/eavesdrop/network_test_1.yml
  read1:
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"  
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head profile="http://gmpg.org/xfn/11">
    ... etc

  # unplug your network, run the test again, it should pass :)

=end

require 'eavesdrop/instance_exec'
require 'socket'

# class TCPSocket  
#   class << self
#     alias_method :untapped_open, :open
# 
#     def open(*args)
#       puts "*** open(#{args.inspect})"
#       socket = old_open(*args)
#       Eavesdrop::Monitor.attach(socket, :read, :sysread)
#       socket
#     end
#   end
# end

module Eavesdrop
  def self.included(*args)
    puts "I was just included with args #{args.inspect}"
    # ...
  end
  
  def eavesdrop
    
  end
  
  class Proxy
    def initialize(instance)
      @real_object = instance
    end
    
    def method_missing(method, *args)
      puts "called #{method}"
      result = @real_object.send(method, *args)
    end
  end
  
  class Monitor
    class << self
      attr_accessor :buffer
    end

    def self.record(*args)
      self.buffer ||= []
      self.buffer += args
    end
    
    def self.reset!
      self.buffer = nil
    end

    def self.attach(object, *target_methods)
      target_methods.map!{|m| m.to_s}
      
      object.class.class_eval do
        target_methods.each do |method|
          tapped_method = "tapped_#{method}"
          if !self.class.method_defined?(tapped_method)          
            define_method(tapped_method) do |*args|
              #puts "#{method} called"
              result = self.send("untapped_#{method}".to_sym, *args)
              Eavesdrop::Monitor.record(result)
              result
            end
          end
        end
      end
      
      object.instance_eval do |o|
        target_methods.each do |method|
          #puts "#{self}: alias #{method}"
          #raise ['alias_method', "untapped_#{method}", method].inspect
          untapped_method = "untapped_#{method}"
          tapped_method = "tapped_#{method}"          
          if !self.class.method_defined?(untapped_method)
            self.class.send(:alias_method, untapped_method, method)
          end
          self.class.send(:alias_method, method, tapped_method)
        end
      end
    end  
    
    def self.inject_proxy(klass, method)
      untapped_method = "untapped_#{method}"
      tapped_method = "tapped_#{method}"          
      klass.class_eval do
        (class << self; self; end).send(:alias_method, untapped_method, method)
        (class << self; self; end).send(:define_method, tapped_method) do |*args|
          puts "#{method} called"
          instance = self.send("untapped_#{method}".to_sym, *args)
          Eavesdrop::Proxy.new(instance)
        end                
        (class << self; self; end).send(:alias_method, method, tapped_method)        
      end
    end
  end
  
end