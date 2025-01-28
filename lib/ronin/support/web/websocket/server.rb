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
        # Represents a WebSocket server.
        #
        class Server

          include URLMethods

          # The underlying server socket.
          #
          # @return [TCPServer, OpenSSL::SSL::SSLServer]
          attr_reader :socket

          #
          # Initializes the WebSocket server.
          #
          # @param [String, URI::WS, URI::WSS] url
          #   The `ws://` or `wss://` URL.
          #
          # @param [String, nil] bind_host
          #   The optional host to bind the server socket to.
          #
          # @param [Integer, nil] bind_port
          #   The optioanl port to bind the server socket to. If not specified,
          #   it will default to the port of the URL.
          #
          # @param [Integer] backlog
          #   The maximum backlog of pending connections.
          #
          # @param [Hash{Symbol => Object}] ssl
          #   Additional keyword arguments for
          #   `Ronin::Support::Network::SSL.server`.
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
          def initialize(url, bind_host: nil,
                              bind_port: nil,
                              backlog:   5,
                              ssl:       {})
            super(url)

            @bind_host = bind_host
            @bind_port = bind_port || @port

            @socket = case @url.scheme
                      when 'ws'
                        Support::Network::TCP.server(
                          host:    @bind_host,
                          port:    @bind_port,
                          backlog: backlog
                        )
                      when 'wss'
                        Support::Network::SSL.server(
                          host:    @bind_host,
                          port:    @bind_port,
                          backlog: backlog,
                          **ssl
                        )
                      else
                        raise(ArgumentError,"unsupported websocket scheme: #{url}")
                      end
          end

          #
          # Sets the connection backlog for the server socket.
          #
          # @param [Integer] backlog
          #   The number of pending connection to allow.
          #
          def listen(backlog)
            @socket.listen(backlog)
          end

          #
          # Accepts a new WebSocket connection.
          #
          # @return [Client]
          #   The new WebSocket connection to the server.
          #
          def accept
            Client.new(@url,@socket.accept)
          end

          #
          # Closes the WebSocket server's socket.
          #
          # @api public
          #
          def close
            @socket.close
          end

          #
          # Determines if the WebSocket server is closed?
          #
          # @return [Boolean]
          #
          # @api public
          #
          def closed?
            @socket.closed?
          end

          #
          # Represents a WebSocket client connected to the Websocket server.
          #
          class Client < Socket

            #
            # Initializes a WebSocket server client.
            #
            # @param [URI::WS, URI::WSS] url
            #   The WebSocket server's `ws://` or `wss://` URL.
            #
            # @param [TCPSocket, OpenSSL::SSL::SSLSocket] socket
            #   The client's connection socket.
            #
            # @api private
            #
            def initialize(url,socket)
              super()

              @url    = url
              @socket = socket

              receive_handshake!

              set_frame_classes(
                ::WebSocket::Frame::Incoming::Server,
                ::WebSocket::Frame::Outgoing::Server
              )
            end

            #
            # Receives the WebSocket handshake.
            #
            # @api private
            #
            def receive_handshake!(**kwargs)
              @handshake = ::WebSocket::Handshake::Server.new(
                url: @url.to_s, **kwargs
              )

              @handshake << @socket.readpartial(1024) until @handshake.finished?

              if @handshake.valid?
                @socket.write(@handshake)
              end
            end

          end

        end
      end
    end
  end
end
