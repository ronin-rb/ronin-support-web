# frozen_string_literal: true
#
# ronin-support-web - A web support library for ronin-rb.
#
# Copyright (c) 2023-2026 Hal Brodigan (postmodern.mod3@gmail.com)
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
      # XML helper methods.
      #
      module XML
        #
        # Parses the body of a document into a HTML document object.
        #
        # @param [String, IO] xml
        #   The XML to parse.
        #
        # @yield [doc]
        #   If a block is given, it will be passed the newly created document
        #   object.
        #
        # @yieldparam [Nokogiri::XML::Document] doc
        #   The new XML document object.
        #
        # @return [Nokogiri::XML::Document]
        #   The new HTML document object.
        #
        # @see http://rubydoc.info/gems/nokogiri/Nokogiri/XML/Document
        #
        # @api public
        #
        def self.parse(xml)
          doc = Nokogiri::XML.parse(xml)
          yield doc if block_given?
          return doc
        end

        #
        # Opens an XML file.
        #
        # @param [String] path
        #   The path to the XML file.
        #
        # @yield [doc]
        #   If a block is given, it will be passed the newly created document
        #   object.
        #
        # @yieldparam [Nokogiri::XML::Document] doc
        #   The new XML document object.
        #
        # @return [Nokogiri::XML::Document]
        #   The parsed XML file.
        #
        # @example
        #   doc = XML.open('data.xml')
        #   # => #<Nokogiri::XML::Document:...>
        #
        # @api public
        #
        def self.open(path)
          doc = Nokogiri::XML(File.open(path))
          yield doc if block_given?
          return doc
        end

        #
        # Creates a new `Nokogiri::XML::Builder`.
        #
        # @yield []
        #   The block that will be used to construct the XML document.
        #
        # @return [Nokogiri::XML::Builder]
        #   The new XML builder object.
        #
        # @example
        #   XML.build do
        #     root {
        #       foo(id: 'bar')
        #     }
        #   end
        #
        # @see http://rubydoc.info/gems/nokogiri/Nokogiri/XML/Builder
        #
        # @api public
        #
        def self.build(&block)
          Nokogiri::XML::Builder.new(&block)
        end
      end
    end
  end
end
