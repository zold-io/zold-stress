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
require 'zold/key'
require 'zold/id'
require 'zold/log'
require 'zold/http'
require 'zold/score'
require 'zold/wallets'
require 'zold/remotes'
require 'zold/verbose_thread'
require 'zold/commands/node'
require 'tmpdir'
require 'random-port'
require_relative '../test__helper'

module Zold::Stress
  class FakeNode
    def initialize(log)
      @log = log
    end

    def exec
      RandomPort::Pool::SINGLETON.acquire do |port|
        Dir.mktmpdir do |home|
          thread = Thread.start do
            Thread.current.name = 'fake_node'
            Zold::VerboseThread.new(@log).run do
              node = Zold::Node.new(
                wallets: Zold::Wallets.new(home),
                remotes: Zold::Remotes.new(file: File.join(home, 'remotes')),
                copies: File.join(home, 'copies'),
                log: @log
              )
              node.run(
                [
                  '--home', home,
                  '--network=test',
                  '--port', port.to_s,
                  '--host=localhost',
                  '--bind-port', port.to_s,
                  '--threads=0',
                  '--standalone',
                  '--no-metronome',
                  '--dump-errors',
                  '--halt-code=test',
                  '--strength=2',
                  '--routine-immediately',
                  '--invoice=NOPREFIX@ffffffffffffffff'
                ]
              )
            end
          end
          attempt = 0
          loop do
            code = Zold::Http.new(uri: "http://localhost:#{port}/").get.status
            break if code == 200
            @log.debug("Waiting for the node at localhost:#{port} (attempt no.#{attempt}): #{code}...")
            attempt += 1
            sleep 1
            raise 'Can\'t start a node' if attempt > 100
          end
          begin
            yield port
          ensure
            Zold::Http.new(uri: "http://localhost:#{port}/?halt=test").get
            thread.join
          end
        end
      end
    end
  end
end
