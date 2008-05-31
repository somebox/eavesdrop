
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

class DummyNew
  attr_accessor :a
  def initialize
    @a = "yes"
  end
end

class MyObject
end
