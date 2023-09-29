# ronin-support-web

[![CI](https://github.com/ronin-rb/ronin-support-web/actions/workflows/ruby.yml/badge.svg)](https://github.com/ronin-rb/ronin-support-web/actions/workflows/ruby.yml)
[![Code Climate](https://codeclimate.com/github/ronin-rb/ronin-support-web.svg)](https://codeclimate.com/github/ronin-rb/ronin-support-web)

* [Website](https://ronin-rb.dev/)
* [Source](https://github.com/ronin-rb/ronin-support-web)
* [Issues](https://github.com/ronin-rb/ronin-support-web/issues)
* [Documentation](https://ronin-rb.dev/docs/ronin-support-web)
* [Discord](https://discord.gg/6WAb3PsVX9) |
  [Mastodon](https://infosec.exchange/@ronin_rb)

## Description

ronin-support-web is a web support library for ronin-rb. ronin-support-web
provides many helper methods for parsing HTML/XML, fetching web pages, etc.

## Features

* Provides helper methods for parsing HTML/XML.

## Requirements

* [Ruby] >= 3.0.0
* [ronin-support] ~> 1.0
* [nokogiri] ~> 1.4
* [nokogiri-ext] ~> 0.1
* [mechanize] ~> 2.0

## Install

```shell
$ gem install ronin-support-web
```

### Gemfile

```ruby
gem 'ronin-support-web', '~> 0.1'
```

### gemspec

```ruby
gem.add_dependency 'ronin-support-web', '~> 0.1'
```

## Development

1. [Fork It!](https://github.com/ronin-rb/ronin-support-web/fork)
2. Clone It!
3. `cd ronin-support-web/`
4. `bundle install`
5. `git checkout -b my_feature`
6. Code It!
7. `bundle exec rake spec`
8. `git push origin my_feature`

## License

ronin-support-web - A web support library for ronin-rb.

Copyright (c) 2023 Hal Brodigan (postmodern.mod3@gmail.com)

ronin-support-web is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ronin-support-web is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with ronin-support-web.  If not, see <https://www.gnu.org/licenses/>.

[Ruby]: https://www.ruby-lang.org
[nokogiri]: https://nokogiri.org/
[nokogiri-ext]: https://github.com/postmodern/nokogiri-ext#readme
[mechanize]: https://github.com/sparklemotion/mechanize#readme
[ronin-support]: https://github.com/ronin-rb/ronin-support#readme
