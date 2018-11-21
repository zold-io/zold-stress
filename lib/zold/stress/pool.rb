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
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'zold/log'
require 'zold/id'
require 'zold/key'
require 'zold/amount'
require 'zold/commands/create'
require 'zold/commands/pull'
require 'zold/commands/remove'
require 'parallelize'
require_relative 'stats'

# Pool of wallets.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018 Yegor Bugayenko
# License:: MIT
module Zold::Stress
  # Pool of wallets.
  class Pool
    def initialize(wallets:, remotes:, copies:, stats:, opts:,
      log: Zold::Log::NULL, vlog: Zold::Log::NULL)
      @wallets = wallets
      @remotes = remotes
      @copies = copies
      @log = log
      @vlog = vlog
      @opts = opts
      @stats = stats
    end

    def rebuild
      raise "There are no wallets in the pool at #{@wallets.path}, at least one is needed" if @wallets.all.empty?
      balances = @wallets.all
        .map { |id| { id: id, balance: @wallets.acq(id, &:balance) } }
        .sort_by { |h| h[:balance] }
        .reverse
      balances.last([balances.count - @opts['pool'], 0].max).each do |h|
        Zold::Remove.new(wallets: @wallets, log: @vlog).run(
          ['remove', h[:id].to_s]
        )
      end
      Tempfile.open do |f|
        File.write(f, @wallets.acq(balances[0][:id], &:key).to_s)
        while @wallets.all.count < @opts['pool']
          Zold::Create.new(wallets: @wallets, log: @vlog).run(
            ['create', "--public-key=#{f.path}", "--network=#{@opts['network']}"] + @opts.arguments
          )
        end
      end
      return if balances.find { |b| b[:balance].positive? }
      raise "There is not a single wallet among #{balances.count} with a positive balance, in #{@wallets.path}: \
  #{balances.map { |b| "#{b[:id]}: #{b[:balance]}" }.join("\n")}"
    end
  end
end
