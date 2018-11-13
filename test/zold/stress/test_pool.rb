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
require 'zold/key'
require 'zold/id'
require 'zold/log'
require 'zold/wallets'
require 'zold/sync_wallets'
require 'zold/remotes'
require 'tmpdir'
require 'slop'
require_relative '../test__helper'
require_relative 'fake_node'
require_relative '../../../lib/zold/stress/pool'
require_relative '../../../lib/zold/stress/stats'

class PoolTest < Minitest::Test
  def test_reloads_wallets
    Zold::Stress::FakeNode.new(test_log).exec do |port|
      Dir.mktmpdir do |home|
        wallets = Zold::SyncWallets.new(Zold::Wallets.new(home))
        Zold::Create.new(wallets: wallets, log: test_log).run(
          ['create', '--public-key=fixtures/id_rsa.pub', Zold::Id::ROOT.to_s, '--network=test']
        )
        wallets.find(Zold::Id::ROOT) do |w|
          w.add(Zold::Txn.new(1, Time.now, Zold::Amount.new(zld: 1.0), 'NOPREFIX', Zold::Id.new, '-'))
        end
        remotes = Zold::Remotes.new(file: File.join(home, 'remotes'), network: 'test')
        remotes.clean
        remotes.add('localhost', port)
        size = 3
        Zold::Stress::Pool.new(
          wallets: wallets,
          remotes: remotes,
          copies: File.join(home, 'copies'),
          stats: Zold::Stress::Stats.new,
          opts: test_opts("--pool=#{size}"),
          log: test_log, vlog: test_log
        ).rebuild
        assert_equal(size, wallets.all.count)
      end
    end
  end
end
