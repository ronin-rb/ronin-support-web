# frozen_string_literal: true
#
# ronin-support-web - A web support library for ronin-rb.
#
# Copyright (c) 2023-2024 Hal Brodigan (postmodern.mod3@gmail.com)
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

require 'uri'

module Ronin
  module Support
    module Web
      module WebSocket
        #
        # Mixin which accepts and parses a `ws://` or `wss://` URL.
        #
        # @api private
        #
        module URLMethods
          # The parsed `ws://` or `wss://` URI.
          #
          # @return [URI::WS, URI::WSS]
          #
          # @api public
          attr_reader :url

          # The websocket host name.
          #
          # @return [String]
          #
          # @api public
          attr_reader :host

          # The websocket port.
          #
          # @return [Integer]
          #
          # @api public
          attr_reader :port

          # The websocket port.
          #
          # @return [String]
          #
          # @api public
          attr_reader :path

          #
          # Sets the {#url}.
          #
          # @param [String] url
          #   The `ws://` or `wss://` URL.
          #
          # @api public
          #
          def initialize(url)
            @url  = URI(url)
            @host = @url.host
            @port = @url.port
            @path = @url.path
            @ssl  = (@url.scheme == 'wss')
          end

          #
          # Determines whether the websocket uses SSL/TLS.
          #
          # @return [Boolean]
          #
          # @api public
          #
          def ssl?
            @ssl
          end
        end
      end
    end
  end
end
