# frozen_string_literal: true
#
# ronin-support-web - A web support library for ronin-rb.
#
# Copyright (c) 2023-2025 Hal Brodigan (postmodern.mod3@gmail.com)
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

require_relative '../xml'

module Ronin
  module Support
    module Web
      module XML
        #
        # Provides helper methods for working with XML.
        #
        # @api public
        #
        module Mixin
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
          # @see XML.parse
          #
          def xml_parse(xml,&block)
            XML.parse(xml,&block)
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
          #   doc = XML.open('index.xml')
          #   # => #<Nokogiri::XML::Document:...>
          #
          # @see http://rubydoc.info/gems/nokogiri/Nokogiri/XML/Document
          # @see XML.open
          #
          def xml_open(path,&block)
            XML.open(path,&block)
          end

          alias open_xml xml_open

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
          #   xml_build do
          #     root {
          #       foo(id: 'bar')
          #     }
          #   end
          #
          # @see http://rubydoc.info/gems/nokogiri/Nokogiri/XML/Builder
          # @see XML.build
          #
          def xml_build(&block)
            XML.build(&block)
          end
        end
      end
    end
  end
end
