require File.dirname(__FILE__) + '/test_helper.rb'

class TestEavesdrop < Test::Unit::TestCase

  # classes for testing
  
  class Dummy
    def hello
      return "hi"
    end

    def self.open
      return Dummy.new
    end
  end
  
  class DummyWithParameters
    attr_accessor :param, :last_param
    
    def one_param(param)
      @param = param
      return "got #{param}"
    end
    
    def handle(*args)
      @last_param = args[-1]
      return "got #{args.join(',')}"
    end
  end
  
  # <><><><>

  def setup
    Eavesdrop::Monitor.reset!
  end
  
  def test_factory_method_with_proxy
    Eavesdrop::Monitor.inject_proxy(Dummy, :open)
    assert_equal Eavesdrop::Proxy, Dummy.open.class
  end
  
  def test_factory_method_proxy_can_call_underlying_methods
    
  end
  
  def test_monitored_methods_are_aliased
    d = Dummy.new
    Eavesdrop::Monitor.attach(d, :hello)
    assert d.respond_to?(:hello)
    assert d.respond_to?(:untapped_hello)
    assert d.methods.include?("untapped_hello")
  end

  def test_aliased_method_returns_results
    d = Dummy.new
    Eavesdrop::Monitor.attach(d, :hello)
    assert_equal "hi", d.untapped_hello
  end
  
  def test_monitored_methods_still_return_results
    d = Dummy.new
    Eavesdrop::Monitor.attach(d, :hello)
    assert_equal "hi", d.hello
  end
  
  def test_monitored_methods_are_tapped
    d = Dummy.new
    Eavesdrop::Monitor.attach(d, :hello)
    d.hello
    assert_equal ['hi'], Eavesdrop::Monitor.buffer
  end
  
  def test_dummy_class_with_one_param
    d = DummyWithParameters.new
    assert_equal "got test", d.one_param('test')
    assert_equal "test", d.param
  end
  
  def test_monitored_method_with_arguments
    d = DummyWithParameters.new
    Eavesdrop::Monitor.attach(d, :one_param)
    assert_equal "got test", d.one_param('test')
    assert_equal "test", d.param
    assert_equal ["got test"], Eavesdrop::Monitor.buffer 
  end

  def test_monitored_method_called_several_times
    d = DummyWithParameters.new
    Eavesdrop::Monitor.attach(d, :one_param)
    (1..3).each{|i| d.one_param(i) }
    assert_equal ["got 1","got 2","got 3"], Eavesdrop::Monitor.buffer      
  end

  def test_dummy_method_with_many_arguments
    d = DummyWithParameters.new
    d.handle(1,2,3)
    assert_equal "got 1,2,3", d.handle(1,2,3)
    assert_equal 3, d.last_param
  end
  
  def test_monitored_method_with_many_arguments
    d = DummyWithParameters.new
    Eavesdrop::Monitor.attach(d, :handle)
    assert_equal "got 1,2,3", d.handle(1,2,3)
    assert_equal 3, d.last_param
    assert_equal ["got 1,2,3"], Eavesdrop::Monitor.buffer        
  end
    
  def test_tcp_monitor
    # require 'socket'
    # result = Net::HTTP.get(URI.parse("http://news.google.com"))
    # assert_equal "result", result
  end
end
