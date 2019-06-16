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
require 'zold/size'

# Summary line.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018-2019 Yegor Bugayenko
# License:: MIT
module Zold::Stress
  # Summary line
  class Summary
    def initialize(stats, batch = 0)
      @stats = stats
      @batch = batch
    end

    def tps
      @batch / @stats.avg('arrived')
    end

    def to_s
      [
        "#{tps.round(2)} tps",
        %w[update push pull paid arrived].map do |m|
          if @stats.exists?(m)
            t = "#{m}: #{@stats.total(m)}/#{Zold::Age.new(Time.now - @stats.avg(m), limit: 2)}"
            errors = @stats.total(m + '_error')
            t += errors.zero? ? '' : '/' + Rainbow(errors.to_s).red
            t
          else
            "#{m}: none"
          end
        end,
        "in: #{Zold::Size.new(@stats.sum('input'))}",
        "out: #{Zold::Size.new(@stats.sum('output'))}"
      ].join('; ')
    end
  end
end
