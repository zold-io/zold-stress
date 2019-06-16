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

# Payments still flying in air.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018-2019 Yegor Bugayenko
# License:: MIT
module Zold::Stress
  # Flying payments.
  class Air
    def initialize
      @mutex = Mutex.new
      @all = []
    end

    def fetch(any = false)
      @all.select { |p| any || p[:arrived].nil? }
    end

    def add(pmt)
      @mutex.synchronize do
        raise "Payment already exists (#{@all.size} total): #{pmt}" if @all.find { |p| p[:details] == pmt[:details] }
        @all << pmt.merge(pushed: Time.now)
      end
    end

    def pulled(id)
      @mutex.synchronize do
        @all.select { |a| a[:target] == id }.each { |a| a[:pulled] = Time.now }
      end
    end

    def arrived(pmt)
      @mutex.synchronize do
        found = @all.find { |p| p[:details] == pmt[:details] }
        raise "Payment doesn't exist (#{@all.size} total): #{pmt}" if found.nil?
        found[:arrived] = Time.now
      end
    end
  end
end
