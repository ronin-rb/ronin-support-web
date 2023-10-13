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

## Examples

```ruby
require 'ronin/support/web'
include Ronin::Support::Web

html_parse "<html>...</html>"
# => #<Nokogiri::HTML::Document:...>
```

### HTML

Parse an HTML string:

```ruby
doc = html_parse("<html>\n  <body>\n    <p>Hello world</p>\n  </body>\n</html>\n")
# => 
# #(Document:0x6ab8 {
#   name = "document",
#   children = [
#     #(DTD:0x6be4 { name = "html" }),
#     #(Element:0x6cd4 {
#       name = "html",
#       children = [
#         #(Text "\n  "),
#         #(Element:0x6e64 {
#           name = "body",
#           children = [
#             #(Text "\n    "),
#             #(Element:0x6ff4 { name = "p", children = [ #(Text "Hello world")] }),
#             #(Text "\n  ")]
#           }),
#         #(Text "\n")]
#       })]
#   })
```

Parse a HTML file:

```ruby
doc = html_open("index.html")
# => #<Nokogiri::HTML::Document:...>
```

Searching an HTML document using [XPath] or CSS-path:

```ruby
nodes = doc.search('//div/p')
nodes = doc.search('div p.class')
# => [#<Nokogiri::HTML::Element:...>, ...]

node = doc.at('#id')
# => #<Nokogiri::HTML::Element:...>
```

Build a HTML document:

```ruby
doc = html_build do
  html {
    head {
      script(type: 'text/javascript', src: 'redirect.js')
    }
  }
end

puts doc.to_html
# <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
# <html><head><script src="redirect.js" type="text/javascript"></script></head></html>
```

### XML

Parse an XML response body:

```ruby
xml_parse("<?xml version=\"1.0\"?>\n<users>\n  <user>\n    <name>admin</name>\n    <password>0mni</password>\n  <user>\n</users>\n")
# =>
# #(Document:0xdebc {
#   name = "document",
#   children = [
#     #(Element:0xdfe8 {
#       name = "users",
#       children = [
#         #(Text "\n  "),
#         #(Element:0xe178 {
#           name = "user",
#           children = [
#             #(Text "\n    "),
#             #(Element:0xe308 { name = "name", children = [ #(Text "admin")] }),
#             #(Text "\n    "),
#             #(Element:0xe538 { name = "password", children = [ #(Text "0mni")] }),
#             #(Text "\n  "),
#             #(Element:0xe768 { name = "user", children = [ #(Text "\n")] }),
#             #(Text "\n")]
#           })]
#       })]
#   })
```

Parse a XML file:

```ruby
doc = html_open("data.xml")
# => #<Nokogiri:XML:::Document:...>
```

Searching an XML document using [XPath]:

```ruby
users = doc.search('//user')
# => [#<Nokogiri::XML::Element:...>, ...]

admin = doc.at('//user[@name="admin"]')
# => #<Nokogiri::XML::Element:...>
```

Build a XML document:

```ruby
doc = xml_build do
  playlist {
    mp3 {
      file { text('02 THE WAIT.mp3') }
      artist { text('Evil Nine') }
      track { text('The Wait feat David Autokratz') }
      duration { text('1000000000') }
    }
  }
end

puts doc.to_xml
# <?xml version="1.0"?>
# <playlist>
#   <mp3>
#     <file>02 THE WAIT.mp3</file>
#     <artist>Evil Nine</artist>
#     <track>The Wait feat David Autokratz</track>
#     <duration>1000000000</duration>
#   </mp3>
# </playlist>
```

### Web Requests

Gets a URL and follows any redirects:

```ruby
get 'https://example.com/'
# => #<Net::HTTPResponse:...>
```

Gets a URL and parses the HTML response:

```ruby
get_html 'https://example.com/'
# => #<Nokogiri::HTML::Document:...>
```

Gets a URL and parses the XML response:

```ruby
get_xml 'https://example.com/sitemap.xml'
# => #<Nokogiri::XML::Document:...>
```

Gets a URL and parses the JSON response:

```ruby
get_json 'https://example.com/api/endpoint.json'
# => {...}
```

POSTs to a URL and follows any redirects:

```ruby
post 'https://example.com/form', form_data: {'foo' => 'bar'}
# => #<Net::HTTPResponse:...>
```

POSTs to a URL and parses the HTML response:

```ruby
post_html 'https://example.com/form', form_data: {'foo' => 'bar'}
# => #<Nokogiri::HTML::Document:...>
```

POSTs to a URL and parses the XML response:

```ruby
post_xml 'https://example.com/form', form_data: {'foo' => 'bar'}
# => #<Nokogiri::XML::Document:...>
```

POSTs to a URL and parses the JSON response:

```ruby
post_json 'https://example.com/api/endpoint.json', json: {foo: 'bar'}
# => {...}
```

## Requirements

* [Ruby] >= 3.0.0
* [ronin-support] ~> 1.1
* [nokogiri] ~> 1.4
* [nokogiri-ext] ~> 0.1

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
[ronin-support]: https://github.com/ronin-rb/ronin-support#readme

[XPath]: https://developer.mozilla.org/en-US/docs/Web/XPath
