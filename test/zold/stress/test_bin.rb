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
require 'tmpdir'
require 'open3'
require 'English'
require 'zold/age'
require_relative '../test__helper'

# Bin test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018 Yegor Bugayenko
# License:: MIT
class TestBin < Minitest::Test
  Dir.new('fixtures/scripts').select { |f| f =~ /\.sh$/ && !f.start_with?('_') }.each do |f|
    define_method("test_#{f.gsub(/\.sh$/, '').gsub(/[^a-z]/, '_')}") do
      start = Time.now
      test_log.debug("\n\n#{f} running...")
      Dir.mktmpdir do |dir|
        FileUtils.cp('fixtures/id_rsa.pub', dir)
        FileUtils.cp('fixtures/id_rsa', dir)
        script = File.join(dir, f)
        IO.write(script, IO.read('fixtures/scripts/_head.sh') + IO.read(File.join('fixtures/scripts', f)))
        bin = File.join(Dir.pwd, 'bin/zold-stress')
        out = []
        Dir.chdir(dir) do
          Open3.popen2e("/bin/bash #{f} #{bin} 2>&1") do |stdin, stdout, thr|
            stdin.close
            until stdout.eof?
              line = stdout.gets
              test_log.debug(line)
              out << line
            end
            code = thr.value.to_i
            assert_equal(0, code, "#{f}\n#{out.join}")
          end
        end
      end
      test_log.debug("\n\n#{f} done in #{Zold::Age.new(start)}")
    end
  end

  private

  def exec(tail, dir = Dir.pwd)
    bin = File.expand_path(File.join(Dir.pwd, 'bin/zold-stress'))
    stdout = `cd #{dir} && #{bin} #{tail} 2>&1`
    unless $CHILD_STATUS.exitstatus.zero?
      puts stdout
      assert_equal($CHILD_STATUS.exitstatus, 0)
    end
    stdout
  end
end
