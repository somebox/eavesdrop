= eavesdrop

* FIX (url)

== DESCRIPTION:

Eavesdrop was designed to capture network traffic (by messing with TCPSocket) and allow the conversation to be recorded, to a file for instance. It also allows these conversations to be replayed. The goal is to allow for a suite of tests that work against "real" network resources, but are repeatable and easier to maintain.

As this goal was explored, the opportunity was realized that any class or object could be recorded (and later replayed). Eavesdrop does this by hooking into a factory method, such as new(), open(), create(), or any user-specified class methods.

To this extent Eavesdrop can be used for many purposes, beyond sniffing in on network classes. For instance, user input, system inspection, etc. It can also be used to observe how a class works, without having to step through a long debugging process. A class can be monitored, and after a program run, the method calls and return results can be analyzed.


=== Using it in tests

Consider the following test, in which live network access is used. By wrapping the test
in Eavesdrop, the results of update_news_from() is saved to the file 'network_test_1'
when first run. After that, subsequent runs will return the same results, without hitting the
network. The TCPSocket class is not being used at all, and the canned responses from before
are used instead.

  def test_something_network_related
    TCPSocket.eavesdrop('network_test_1') do 
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

== FEATURES/PROBLEMS:

  Keep track of the amount of time it took between each method, and have the option to replay in real time.

== SYNOPSIS:

  FIX (code sample of usage)

== REQUIREMENTS:

* FIX (list of requirements)

== INSTALL:

* FIX (sudo gem install, anything else)

== LICENSE:

(The MIT License)

Copyright (c) 2008 FIX

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.