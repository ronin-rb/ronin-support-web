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

require 'ronin/support/web/html'

module Ronin
  module Support
    module Web
      module HTML
        #
        # Provides helper methods for working with HTML.
        #
        # @api public
        #
        module Mixin
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
          # @see HTML.parse
          #
          def html_parse(html,&block)
            HTML.parse(html,&block)
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
          #   html_build do
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
          # @see HTML.build
          #
          def html_build(&block)
            HTML.build(&block)
          end
        end
      end
    end
  end
end
