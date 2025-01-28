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

require_relative 'socket'
require_relative 'url_methods'

require 'ronin/support/network/tcp'
require 'ronin/support/network/ssl'

require 'websocket'

module Ronin
  module Support
    module Web
      module WebSocket
        #
        # Represents a WebSocket client.
        #
        class Client < Socket

          include URLMethods

          #
          # Initializes the WebSocket client.
          #
          # @param [String, URI::WS, URI::WSS] url
          #   The `ws://` or `wss://` URL.
          #
          # @param [Hash{Symbol => Object}] kwargs
          #   Additional keyword arguments for.
          #
          # @option kwargs [String, nil] :bind_host
          #   The optional host to bind the server socket to.
          #
          # @option kwargs [Integer, nil] :bind_port
          #   The optioanl port to bind the server socket to. If not specified,
          #   it will default to the port of the URL.
          #
          # @param [Hash{Symbol => Object}] ssl
          #   Additional keyword arguments for
          #   `Ronin::Support::Network::SSL.connect`.
          #
          # @option ssl [1, 1.1, 1.2, String, Symbol, nil] :version
          #   The SSL version to use.
          #
          # @option ssl [Symbol, Boolean] :verify
          #   Specifies whether to verify the SSL certificate.
          #   May be one of the following:
          #
          #   * `:none`
          #   * `:peer`
          #   * `:fail_if_no_peer_cert`
          #   * `:client_once`
          #
          # @option ssl [Crypto::Key::RSA, OpenSSL::PKey::RSA, nil] :key
          #   The RSA key to use for the SSL context.
          #
          # @option ssl [String] :key_file
          #   The path to the SSL `.key` file.
          #
          # @option ssl [Crypto::Cert, OpenSSL::X509::Certificate, nil] :cert
          #   The X509 certificate to use for the SSL context.
          #
          # @option ssl [String] :cert_file
          #   The path to the SSL `.crt` file.
          #
          # @option ssl [String] :ca_bundle
          #   Path to the CA certificate file or directory.
          #
          def initialize(url, ssl: {}, **kwargs)
            super(url)

            @socket = case @url.scheme
                      when 'ws'
                        Support::Network::TCP.connect(
                          @host, @port, **kwargs
                        )
                      when 'wss'
                        Support::Network::SSL.connect(
                          @host, @port, **kwargs, **ssl
                        )
                      else
                        raise(ArgumentError,"unsupported websocket scheme: #{url}")
                      end

            send_handshake!

            set_frame_classes(
              ::WebSocket::Frame::Incoming::Client,
              ::WebSocket::Frame::Outgoing::Client
            )
          end

          private

          #
          # @api private
          #
          def send_handshake!(**kwargs)
            @handshake = ::WebSocket::Handshake::Client.new(
              url: @url.to_s, **kwargs
            )

            @socket.write(@handshake.to_s)

            @handshake << @socket.readpartial(1024) until @handshake.finished?
          end

        end
      end
    end
  end
end
