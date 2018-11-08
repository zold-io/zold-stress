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

require 'minitest/autorun'
require 'slop'
require 'zold/key'
require 'zold/id'
require 'zold/log'
require 'zold/http'
require 'zold/score'
require 'zold/wallets'
require 'zold/sync_wallets'
require 'zold/cached_wallets'
require 'zold/remotes'
require 'zold/commands/create'
require 'zold/commands/pay'
require 'zold/commands/push'
require 'zold/commands/node'
require 'tmpdir'
require_relative '../test__helper'
require_relative 'fake_node'
require_relative '../../../lib/zold/stress/round'

class StressTest < Minitest::Test
  def test_runs_a_few_full_cycles
    Zold::Stress::FakeNode.new(Zold::Log::Quiet.new).exec do |port|
      Dir.mktmpdir do |home|
        remotes = Zold::Remotes.new(file: File.join(home, 'remotes'), network: 'test')
        remotes.clean
        remotes.add('localhost', port)
        wallets = Zold::SyncWallets.new(Zold::CachedWallets.new(Zold::Wallets.new(home)))
        Zold::Create.new(wallets: wallets, log: test_log).run(
          ['create', '--public-key=fixtures/id_rsa.pub', Zold::Id::ROOT.to_s, '--network=test']
        )
        wallets.find(Zold::Id::ROOT) do |w|
          w.add(Zold::Txn.new(1, Time.now, Zold::Amount.new(zld: 1.0), 'NOPREFIX', Zold::Id.new, '-'))
        end
        stats = Zold::Stress::Stats.new
        air = Zold::Stress::Air.new
        batch = 20
        round = Zold::Stress::Round.new(
          pvt: Zold::Key.new(file: 'fixtures/id_rsa'),
          wallets: wallets, remotes: remotes,
          air: air, stats: stats,
          opts: test_opts('--pool=5', "--batch=#{batch}"),
          copies: File.join(home, 'copies'),
          log: test_log, vlog: test_log
        )
        round.update
        round.prepare
        round.send
        attempt = 0
        loop do
          break if air.fetch.empty?
          break if attempt > 50
          round.pull
          round.match
          test_log.info(stats.to_console)
          attempt += 1
          sleep 0.2
        end
        assert(air.fetch.empty?)
        assert_equal(batch, stats.total('arrived'))
      end
    end
  end
end
