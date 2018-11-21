# frozen_string_literal: true

# Copyright (c) 2018 Yegor Bugayenko
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

require 'eventmachine'
require 'minitest/autorun'
require 'zold/id'
require 'parallelize'
require_relative '../test__helper'
require_relative '../../../lib/zold/stress/air'

class AirTest < Minitest::Test
  def test_adds_and_removes
    air = Zold::Stress::Air.new
    pmt = { start: Time.now, source: Zold::Id::ROOT, target: Zold::Id::ROOT, details: 'Hi!' }
    air.add(pmt)
    assert_equal(1, air.fetch.count)
    air.fetch.each do |p|
      assert_equal(pmt[:details], p[:details])
    end
    air.pulled(air.fetch[0][:target])
    assert_equal(1, air.fetch.count)
    air.arrived(air.fetch[0])
    assert_equal(0, air.fetch.count)
  end

  def test_adds_and_removes_many
    air = Zold::Stress::Air.new
    5.times do |i|
      pmt = { start: Time.now, source: Zold::Id::ROOT, target: Zold::Id::ROOT, details: i.to_s }
      air.add(pmt)
      assert_equal(i + 1, air.fetch.count)
    end
    air.pulled(air.fetch[0][:target])
    assert_equal(5, air.fetch.count)
    air.arrived(air.fetch[0])
    assert_equal(4, air.fetch.count)
  end
end
