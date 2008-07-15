require File.dirname(__FILE__) + '/test_helper.rb'
require File.dirname(__FILE__) + '/dummy_classes.rb'

require 'socket'
require 'net/http'
require 'net/protocol'
require 'yaml'
require 'pp'

class TestEavesdrop < Test::Unit::TestCase
  
  # <><><><>

  def setup
    Eavesdrop::Monitor.reset!
  end
  
  def test_tcp_eavesdrop_capture
    # NOTE: LIVE NETWORK TEST!!!
    TCPSocket.eavesdrop(:open, :new) do
      Net::HTTP.get_print(URI.parse("http://www.amazon.com/gp/aw/h.html"))
      # save it
      File.open("fixtures/http_read.yml", 'w+') do |f|
        f << YAML.dump(Eavesdrop.transcript)
      end
      # puts Eavesdrop.transcript.inspect
   end
  end
  
  def test_tcp_eavesdrop_replay
    Eavesdrop.playback_mode['Net::BufferedIO'] = true    
    Eavesdrop.transcript = YAML.load_file('fixtures/http_read.yml')
    Net::BufferedIO.eavesdrop(:open, :new) do
      Net::HTTP.get_print(URI.parse("http://www.amazon.com/gp/aw/h.html"))      
    end
  end
  
  def test_transcript
    Eavesdrop.transcript = {
      'Dummy' => [
        ['hello2', Marshal.dump('hi')]
      ]
    }
    Eavesdrop.playback_mode['Dummy'] = true
    Dummy.eavesdrop do
      assert_equal 'hi', Dummy.new.hello2
    end
  end
  
  def test_object_level_eavesdrop_can_capture
    DummyNew.eavesdrop do
      Dummy.new.hello
      assert_equal ['hi'], Eavesdrop::Monitor.buffer
    end
  end
  
  def test_object_level_eavesdrop_with_block
    MyObject.eavesdrop do
      m = MyObject.new
      assert_equal Eavesdrop::Proxy, m.class
    end
  end
  
  def test_factory_method_on_new
    Eavesdrop::Monitor.install(DummyNew, :new)
    obj = DummyNew.new
    assert_equal Eavesdrop::Proxy, obj.class
    assert_equal "yes", obj.a
  end
  
  def test_factory_method_with_proxy
    Eavesdrop::Monitor.install(Dummy, :open)
    assert_equal Eavesdrop::Proxy, Dummy.open.class
  end
  
  def test_factory_method_with_stealth_mode
    Eavesdrop.stealth_mode = true
    Eavesdrop::Monitor.install(Dummy, :open)
    assert_equal Dummy, Dummy.open.class    
  end
  
  def test_proxy_can_call_underlying_methods
    Eavesdrop::Monitor.install(Dummy, :open)
    assert_equal 'hi', Dummy.open.hello
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
