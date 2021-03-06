# frozen_string_literal: true

# Copyright (c) 2018-2019 Yegor Bugayenko
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
require_relative '../test__helper'
require_relative '../../../lib/zold/stress/stats'

class StatsTest < Minitest::Test
  def test_aggregates_metrics
    stats = Zold::Stress::Stats.new
    m = 'metric-1'
    stats.put(m, 0.1)
    stats.put(m, 3.0)
    assert(stats.to_json[m])
    assert_equal(1.55, stats.to_json[m][:avg])
  end

  def test_works_with_empty
    stats = Zold::Stress::Stats.new
    m = 'metric-2'
    assert(!stats.exists?(m))
    assert_equal(0, stats.sum(m))
    assert_equal(0, stats.avg(m))
    assert_equal(0, stats.total(m))
  end
end
