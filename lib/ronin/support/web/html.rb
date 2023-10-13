# frozen_string_literal: true
#
# ronin-support-web - A web support library for ronin-rb.
#
# Copyright (c) 2023 Hal Brodigan (postmodern.mod3@gmail.com)
#
# ronin-support-web is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ronin-support-web is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with ronin-support-web.  If not, see <https://www.gnu.org/licenses/>.
#

require 'nokogiri'

module Ronin
  module Support
    module Web
      #
      # HTML helper methods.
      #
      module HTML
        #
        # Parses the body of a document into a HTML document object.
        #
        # @param [String, IO] html
        #   The HTML to parse.
        #
        # @yield [doc]
        #   If a block is given, it will be passed the newly created document
        #   object.
        #
        # @yieldparam [Nokogiri::HTML::Document] doc
        #   The new HTML document object.
        #
        # @return [Nokogiri::HTML::Document]
        #   The new HTML document object.
        #
        # @see http://rubydoc.info/gems/nokogiri/Nokogiri/HTML/Document
        #
        # @api public
        #
        def self.parse(html)
          doc = Nokogiri::HTML.parse(html)
          yield doc if block_given?
          return doc
        end

        #
        # Opens an HTML file.
        #
        # @param [String] path
        #   The path to the HTML file.
        #
        # @yield [doc]
        #   If a block is given, it will be passed the newly created document
        #   object.
        #
        # @yieldparam [Nokogiri::HTML::Document] doc
        #   The new HTML document object.
        #
        # @return [Nokogiri::HTML::Document]
        #   The parsed HTML file.
        #
        # @example
        #   doc = HTML.open('index.html')
        #   # => #<Nokogiri::HTML::Document:...>
        #
        # @see http://rubydoc.info/gems/nokogiri/Nokogiri/HTML/Document
        #
        # @api public
        #
        def self.open(path)
          doc = Nokogiri::HTML(File.open(path))
          yield doc if block_given?
          return doc
        end

        #
        # Creates a new `Nokogiri::HTML::Builder`.
        #
        # @yield []
        #   The block that will be used to construct the HTML document.
        #
        # @return [Nokogiri::HTML::Builder]
        #   The new HTML builder object.
        #
        # @example
        #   HTML.build do
        #     html {
        #       body {
        #         div(style: 'display:none;') {
        #           object(classid: 'blabla')
        #         }
        #       }
        #     }
        #   end
        #
        # @see http://rubydoc.info/gems/nokogiri/Nokogiri/HTML/Builder
        #
        # @api public
        #
        def self.build(&block)
          Nokogiri::HTML::Builder.new(&block)
        end
      end
    end
  end
end
