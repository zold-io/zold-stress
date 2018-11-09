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

require 'backtrace'
require 'parallelize'
require 'zold/key'
require 'zold/id'
require 'zold/commands/push'
require 'zold/commands/remote'
require_relative 'stats'
require_relative 'pool'
require_relative 'pmnts'
require_relative 'air'

# Stress test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018 Yegor Bugayenko
# License:: MIT
module Zold::Stress
  # Full round of stress test
  class Round
    def initialize(pvt:, wallets:, remotes:, copies:,
      stats:, air:, opts:, log: Zold::Log::Quiet.new, vlog: Zold::Log::Quiet.new)
      @pvt = pvt
      @wallets = wallets
      @remotes = remotes
      @copies = copies
      @opts = opts
      @log = log
      @stats = stats
      @air = air
      @vlog = vlog
    end

    def update
      start = Time.now
      cmd = Zold::Remote.new(remotes: @remotes, log: @vlog)
      args = ['remote'] + @opts.arguments
      cmd.run(args + ['trim'])
      cmd.run(args + ['reset']) if @remotes.all.empty? && @opts['network'] != 'test'
      @stats.exec('update') do
        cmd.run(args + ['update'])
      end
      cmd.run(args + ['select'])
      raise 'There are no remote nodes left' if @remotes.all.empty?
      @log.info("List of remotes updated in #{Zold::Age.new(start)}, #{@remotes.all.count} nodes in the list")
    end

    def prepare
      start = Time.now
      pool = Zold::Stress::Pool.new(
        wallets: @wallets,
        remotes: @remotes, copies: @copies, stats: @stats,
        log: @log, opts: @opts, vlog: @vlog
      )
      pool.rebuild
      @wallets.all.peach(@opts['threads']) do |id|
        @stats.exec('push') do
          Zold::Push.new(wallets: @wallets, remotes: @remotes, log: @vlog).run(
            ['push', id.to_s, "--network=#{@opts['network']}"] + @opts.arguments
          )
        end
      end
      @log.info("There are #{@wallets.all.count} wallets in the pool \
with #{@wallets.all.map { |id| @wallets.find(id, &:balance) }.inject(&:+)} total, \
in #{Zold::Age.new(start)}")
    end

    def send
      start = Time.now
      sent = Zold::Stress::Pmnts.new(
        pvt: @pvt, wallets: @wallets,
        remotes: @remotes, stats: @stats,
        log: @log, opts: @opts, vlog: @vlog
      ).send
      mutex = Mutex.new
      sources = sent.group_by { |p| p[:source] }
      sources.peach(@opts['threads']) do |a|
        @stats.exec('push') do
          Zold::Push.new(wallets: @wallets, remotes: @remotes, log: @vlog).run(
            ['push', a[0].to_s, "--network=#{@opts['network']}"] + @opts.arguments
          )
          mutex.synchronize do
            a[1].each { |p| @air.add(p) }
          end
        end
      end
      @log.info("#{sent.count} payments sent from #{sources.count} wallets, \
in #{Zold::Age.new(start)}, #{@air.fetch.count} are now in the air")
      @log.debug("  #{sent.map { |p| "#{p[:source]} -> #{p[:target]} #{p[:amount]}" }.join("\n  ")}")
    end

    def pull
      start = Time.now
      targets = @air.fetch.group_by { |p| p[:target] }.map { |a| a[0] }
      targets.each do |id|
        next unless @wallets.find(id, &:exists?)
        Zold::Remove.new(wallets: @wallets, log: @vlog).run(
          ['remove', id.to_s]
        )
      end
      targets.peach(@opts['threads']) do |id|
        @stats.exec('pull') do
          Zold::Pull.new(wallets: @wallets, remotes: @remotes, copies: @copies, log: @vlog).run(
            ['pull', id.to_s, "--network=#{@opts['network']}"] + @opts.arguments
          )
        end
      end
      @log.info("There are #{@wallets.all.count} wallets left, \
after the pull of #{targets.count} in #{Zold::Age.new(start)}")
    end

    def match
      total = 0
      @air.fetch.each do |p|
        next unless @wallets.find(p[:target], &:exists?)
        t = @wallets.find(p[:target], &:txns).find { |x| x.details == p[:details] && x.bnf == p[:source] }
        next if t.nil?
        @stats.put('arrived', Time.now - p[:start])
        total += 1
        @log.debug("#{p[:amount]} arrived from #{p[:source]} to #{p[:target]} \
in txn ##{t.id} in #{Zold::Age.new(p[:start])}: #{t.details}")
        @air.delete(p)
      end
      @log.info("#{total} payments just arrived, #{@air.fetch.count} still in the air")
    end
  end
end
