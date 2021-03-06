# frozen_string_literal: true

# Copyright (c) 2016-2018 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

ENV['RACK_ENV'] = 'test'

require 'simplecov'
SimpleCov.start
if ENV['CI'] == 'true'
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require 'zold/hands'
Zold::Hands.start

require 'concurrent'
require 'slop'
require 'minitest/autorun'
module Minitest
  class Test
    def test_log
      require 'zold/log'
      @test_log ||= ENV['TEST_QUIET_LOG'] ? Zold::Log::NULL : Zold::Log::VERBOSE
    end

    def test_opts(*argv)
      Slop.parse(argv + ['--ignore-score-weakness', '--network=test'], suppress_errors: true) do |o|
        o.integer '--pool', default: 3
        o.integer '--rounds', default: 1
        o.integer '--threads', default: Concurrent.processor_count * 2
        o.integer '--batch', default: 4
        o.string '--private-key', default: 'fixtures/id_rsa.pub'
        o.string '--network', default: 'test'
      end
    end
  end
end
