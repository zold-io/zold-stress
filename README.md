<img src="http://www.zold.io/logo.svg" width="92px" height="92px"/>

[![Donate via Zerocracy](https://www.0crat.com/contrib-badge/CAZPZR9FS.svg)](https://www.0crat.com/contrib/CAZPZR9FS)

[![EO principles respected here](http://www.elegantobjects.org/badge.svg)](http://www.elegantobjects.org)
[![Managed by Zerocracy](https://www.0crat.com/badge/CAZPZR9FS.svg)](https://www.0crat.com/p/CAZPZR9FS)
[![DevOps By Rultor.com](http://www.rultor.com/b/yegor256/zold)](http://www.rultor.com/p/yegor256/zold)
[![We recommend RubyMine](http://www.elegantobjects.org/rubymine.svg)](https://www.jetbrains.com/ruby/)

[![Build Status](https://travis-ci.org/zold-io/zold-stress.svg)](https://travis-ci.org/zold-io/zold-stress)
[![PDD status](http://www.0pdd.com/svg?name=zold-io/zold-stress)](http://www.0pdd.com/p?name=zold-io/zold-stress)
[![Gem Version](https://badge.fury.io/rb/zold-stress.svg)](http://badge.fury.io/rb/zold-stress)
[![Test Coverage](https://img.shields.io/codecov/c/github/zold-io/zold-stress.svg)](https://codecov.io/github/zold-io/zold-stress?branch=master)

Here is the [White Paper](https://papers.zold.io/wp.pdf).

Join our [Telegram group](https://t.me/zold_io) to discuss it all live.

The license is [MIT](https://github.com/zold-io/zold-stress/blob/master/LICENSE.txt).

This is a command line Zold network stress testing toolkit. First, you
create an empty directory. Then, create or pull a Zold wallet there. The
wallet has to have some money. Preferrably, a small amount, like 1 ZLD. Then,
you install `zold-stress` Ruby gem, run it, and read the output:

```
$ gem install zold-stress
$ zold-stress --help
```

You will have to install [Ruby](https://www.ruby-lang.org/en/) 2.5.1+ first.

# How to contribute

Read [these guidelines](https://www.yegor256.com/2014/04/15/github-guidelines.html).
Make sure you build is green before you contribute
your pull request. You will need to have [Ruby](https://www.ruby-lang.org/en/) 2.3+ and
[Bundler](https://bundler.io/) installed. Then:

```
$ bundle update
$ rake
```

If it's clean and you don't see any error messages, submit your pull request.
