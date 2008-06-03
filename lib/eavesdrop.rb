 $:.unshift(File.dirname(__FILE__)) unless
   $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'eavesdrop/instance_exec'
require 'socket'

#
# The original plan, which later morphed into insanity
#
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

class Object
  def self.eavesdrop(method=:new)
    Eavesdrop::Monitor.install(self, method)
    yield
    Eavesdrop::Monitor.clear(self, method)
  end
end

module Eavesdrop
  # when stealth mode is true, proxy objects will not reveal their real class through inspection
  class << self
    attr_accessor :stealth_mode, :transcript, :playback_mode
  end

  @playback_mode = {}
  @transcript = {}
  
  # little spy that pretends to be something else
  class Proxy
    def initialize(instance)
      @__real_object = instance     
      @__klass = @__real_object.class.name
      Eavesdrop.transcript[@__klass] ||= []
    end
    
    def method_missing(method, *args)
      arg_string = args.collect{|a|a.inspect}.join(',')
      puts "#{@__real_object.class.name}##{method}(#{arg_string})"
      #puts "#{args.inspect}"
      
      # record/play : if we have monitored this class before, do a playback
      # otherwise, we record
      
      if Eavesdrop.playback_mode[@__klass]
        # TODO: raise exception if method called differs from stack
        to_return = Eavesdrop.transcript[@__klass].pop[1]
        puts " >> " + to_return.inspect
        # Marshal.load(to_return)
        to_return
      else
        retval = @__real_object.send(method, *args)
        # to_store = Marshal.dump(retval)
        to_store = [method.to_s, retval]
        puts " >> #{retval.inspect}"
        Eavesdrop.transcript[@__klass].push(to_store)
        # puts Eavesdrop.transcript.inspect
        return retval
      end        
    end
    
    def class
      return Eavesdrop.stealth_mode ? @__real_object.class : Eavesdrop::Proxy
    end
    
    def ===(klass)
      # TODO
    end
    
    def is_eavesdrop_proxy?
      true
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
      Eavesdrop.stealth_mode = false
      Eavesdrop.transcript = {}
      Eavesdrop.playback_mode = {}
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
    
    def self.install(klass, method)
      # puts "install #{klass}##{method}"
      untapped_method = "untapped_#{method}"
      tapped_method = "tapped_#{method}"
      if klass.respond_to?(tapped_method.to_sym)
        return
#        raise "#{klass.name}##{method} is already injected" 
      end
      klass.class_eval do
        meta = (class << self; self; end)
        meta.send(:alias_method, untapped_method, method)
        meta.send(:define_method, tapped_method) do |*args|
          # puts "#{meta}##{method}"
          instance = self.send("untapped_#{method}".to_sym, *args)
          Eavesdrop::Proxy.new(instance)
        end
        (class << self; self; end).send(:alias_method, method, tapped_method)        
      end
    end
    
    def self.clear(klass, method)
      # todo
    end
  end
  
end