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
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'time'
require 'rainbow'
require 'backtrace'
require 'zold/log'
require 'zold/age'

# Statistics.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018-2019 Yegor Bugayenko
# License:: MIT
module Zold::Stress
  # Stats
  class Stats
    def initialize(log: Zold::Log::NULL)
      @history = {}
      @mutex = Mutex.new
      @log = log
    end

    def exists?(metric)
      !@history[metric].nil?
    end

    def total(metric)
      (@history[metric] || []).count
    end

    def avg(metric)
      sum(metric).to_f / [total(metric), 1].max
    end

    def sum(metric)
      (@history[metric] || []).map { |a| a[:value] }.inject(&:+) || 0
    end

    def to_json
      @history.map do |m, h|
        data = h.map { |a| a[:value] }
        sum = data.inject(&:+) || 0
        [
          m,
          {
            'total': data.count,
            'sum': sum,
            'avg': (data.empty? ? 0 : (sum / data.count)),
            'max': data.max || 0,
            'min': data.min || 0,
            'age': (h.map { |a| a[:time] }.max || 0) - (h.map { |a| a[:time] }.min || 0)
          }
        ]
      end.to_h
    end

    def exec(metric, swallow: true)
      start = Time.now
      yield
      put(metric + '_ok', Time.now - start)
    rescue StandardError => ex
      put(metric + '_error', Time.now - start)
      @log.error(Backtrace.new(ex))
      puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
      raise ex unless swallow
    ensure
      put(metric, Time.now - start)
    end

    def put(metric, value)
      raise "Invalid type of \"#{value}\" (#{value.class.name})" unless value.is_a?(Integer) || value.is_a?(Float)
      @mutex.synchronize do
        @history[metric] = [] unless @history[metric]
        @history[metric] << { time: Time.now, value: value }
      end
    end
  end
end
