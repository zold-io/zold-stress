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
require_relative '../../../lib/zold/stress/stats'
require_relative '../../../lib/zold/stress/summary'
require_relative '../../../lib/zold/stress/air'

class StressTest < Minitest::Test
  def test_runs_a_few_full_cycles
    Zold::Stress::FakeNode.new(Zold::Log::NULL).exec do |port|
      Dir.mktmpdir do |home|
        remotes = Zold::Remotes.new(file: File.join(home, 'remotes'), network: 'test')
        remotes.clean
        remotes.add('localhost', port)
        wallets = Zold::SyncWallets.new(Zold::CachedWallets.new(Zold::Wallets.new(home)))
        Zold::Create.new(wallets: wallets, log: test_log, remotes: nil).run(
          ['create', '--public-key=fixtures/id_rsa.pub', Zold::Id::ROOT.to_s, '--network=test', '--skip-test']
        )
        wallets.acq(Zold::Id::ROOT) do |w|
          w.add(Zold::Txn.new(1, Time.now, Zold::Amount.new(zld: 1.0), 'NOPREFIX', Zold::Id.new, '-'))
        end
        stats = Zold::Stress::Stats.new(log: test_log)
        air = Zold::Stress::Air.new
        batch = 4
        summary = Zold::Stress::Summary.new(stats, batch)
        round = Zold::Stress::Round.new(
          pvt: Zold::Key.new(file: 'fixtures/id_rsa'),
          wallets: wallets,
          remotes: remotes,
          air: air,
          stats: stats,
          opts: test_opts('--pool=5', "--batch=#{batch}"),
          copies: File.join(home, 'copies'),
          log: test_log,
          vlog: test_log
        )
        round.update
        round.prepare
        round.send
        attempt = 0
        loop do
          if air.fetch.empty?
            test_log.info('There is nothing in the air, time to stop')
            break
          end
          break if attempt > 4
          round.pull
          round.match
          test_log.info(summary)
          attempt += 1
          sleep 0.2
        end
        assert(air.fetch.empty?)
        assert_equal(batch, stats.total('arrived'))
      end
    end
  end
end
