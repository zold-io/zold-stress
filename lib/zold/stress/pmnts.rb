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

require 'zold/key'
require 'zold/tax'
require 'zold/commands/pay'
require 'zold/commands/remote'
require 'zold/commands/taxes'
require_relative 'stats'

# Pool of wallets.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018 Yegor Bugayenko
# License:: MIT
module Zold::Stress
  # Payments to send in a batch.
  class Pmnts
    def initialize(pvt:, wallets:, remotes:, stats:, opts:,
      vlog: Zold::Log::Quiet.new, log: Zold::Log::Quiet.new)
      @pvt = pvt
      @wallets = wallets
      @remotes = remotes
      @log = log
      @vlog = vlog
      @opts = opts
      @stats = stats
    end

    def send
      raise 'Too few wallets in the pool' if @wallets.all.count < 2
      paid = []
      Tempfile.open do |f|
        File.write(f, @pvt.to_s)
        loop do
          source = @wallets.all.sample
          balance = @wallets.find(source, &:balance)
          next if balance.negative? || balance.zero?
          amount = balance / @wallets.all.count
          next if amount < Zold::Amount.new(zld: 0.0001)
          loop do
            target = @wallets.all.sample
            next if source == target
            paid << pay_one(source, target, amount, f.path)
            break
          end
          break if paid.count >= @opts['batch']
        end
      end
      paid
    end

    private

    def pay_one(source, target, amount, pvt)
      Zold::Taxes.new(wallets: @wallets, remotes: @remotes, log: @vlog).run(
        [
          'taxes', 'pay', source.to_s, "--network=#{@opts['network']}",
          "--private-key=#{pvt}", '--ignore-nodes-absence'
        ]
      )
      if @wallets.find(source) { |w| Zold::Tax.new(w).in_debt? }
        @log.error("The wallet #{source} is in debt and we can't pay taxes")
        return
      end
      details = SecureRandom.uuid
      @stats.exec('paid', swallow: false) do
        Zold::Pay.new(wallets: @wallets, remotes: @remotes, log: @vlog).run(
          [
            'pay', source.to_s, target.to_s, amount.to_zld(6), details,
            "--network=#{@opts['network']}", "--private-key=#{pvt}"
          ]
        )
      end
      { start: Time.now, source: source, target: target, amount: amount, details: details }
    end
  end
end
