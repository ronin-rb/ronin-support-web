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

require 'ronin/support/web/websocket/client'
require 'ronin/support/web/websocket/server'

require 'uri/ws'
require 'uri/wss'

module Ronin
  module Support
    module Web
      module WebSocket
        #
        # Adds helper methods for working with WebSockets.
        #
        module Mixin
          # @!macro [new] ssl_kwargs
          #   @option ssl [1, 1.1, 1.2, String, Symbol, nil] :version
          #     The SSL version to use.
          #
          #   @option ssl [Symbol, Boolean] :verify
          #     Specifies whether to verify the SSL certificate.
          #     May be one of the following:
          #
          #     * `:none`
          #     * `:peer`
          #     * `:fail_if_no_peer_cert`
          #     * `:client_once`
          #
          #   @option ssl [Crypto::Key::RSA, OpenSSL::PKey::RSA, nil] :key
          #     The RSA key to use for the SSL context.
          #
          #   @option ssl [String] :key_file
          #     The path to the SSL `.key` file.
          #
          #   @option ssl [Crypto::Cert, OpenSSL::X509::Certificate, nil] :cert
          #     The X509 certificate to use for the SSL context.
          #
          #   @option ssl [String] :cert_file
          #     The path to the SSL `.crt` file.
          #
          #   @option ssl [String] :ca_bundle
          #     Path to the CA certificate file or directory.

          # @!macro [new] client_kwargs
          #   @option kwargs [String, nil] :bind_host
          #     The optional host to bind the server socket to.
          #
          #   @option kwargs [Integer, nil] :bind_port
          #     The optioanl port to bind the server socket to. If not
          #     specified, it will default to the port of the URL.
          #
          #   @!macro ssl_kwargs

          # Connects to a websocket.
          #
          # @param [String, URI::WS, URI::WSS] url
          #   The `ws://` or `wss://` URL to connect to.
          #
          # @param [Hash{Symbol => Object}] ssl
          #   Additional keyword arguments for
          #   `Ronin::Support::Network::SSL.connect`.
          #
          # @param [Hash{Symbol => Object}] kwargs
          #   Additional keyword arguments for {Client#initialize}.
          #
          # @!macro client_kwargs
          #
          # @yield [websocket]
          #   If a block is given, then it will be passed the WebSocket
          #   connection. Once the block has returned, the WebSocket connection
          #   will be closed.
          #
          # @yieldparam [Client] websocket
          #   The WebSocket connection.
          #
          # @return [Client]
          #   The WebSocket connection.
          #
          # @example Connecting to a WebSocket server:
          #   websocket_connect('ws://websocket-echo.com')
          #   # => #<Ronin::Support::Web::WebSocket::Client: ...>
          #
          # @example Creating a temporary WebSocket connection:
          #   websocket_connect('ws://websocket-echo.com') do |websocket|
          #     # ...
          #   end
          #
          # @api public
          #
          def websocket_connect(url, ssl: {}, **kwargs)
            client = Client.new(url, ssl: ssl, **kwargs)

            if block_given?
              yield client
              client.close
            else
              client
            end
          end

          #
          # Connects to a WebSocket.
          #
          # @param [String] host
          #   The WebSocket host.
          #
          # @param [Integer] port
          #   The WebSocket port.
          #
          # @param [Hash{Symbol => Object}] ssl
          #   Additional keyword arguments for
          #   `Ronin::Support::Network::SSL.connect`.
          #
          # @param [Hash{Symbol => Object}] kwargs
          #   Additional keyword arguments for {Client#initialize}.
          #
          # @!macro client_kwargs
          #
          # @yield [websocket]
          #   If a block is given, then it will be passed the WebSocket
          #   connection. Once the block has returned, the WebSocket connection
          #   will be closed.
          #
          # @yieldparam [Client] websocket
          #   The WebSocket connection.
          #
          # @return [Client]
          #   The WebSocket connection.
          #
          # @example Connecting to a WebSocket server:
          #   ws_connect('ws://websocket-echo.com')
          #   # => #<Ronin::Support::Web::WebSocket::Client: ...>
          #
          # @example Creating a temporary WebSocket connection:
          #   ws_connect('ws://websocket-echo.com') do |websocket|
          #     # ...
          #   end
          #
          # @api public
          #
          def ws_connect(host,port=80, ssl: {}, **kwargs,&block)
            uri = URI::WS.build(host: host, port: port)

            websocket_connect(uri, ssl: ssl, **kwargs,&block)
          end

          #
          # Connects to a SSL/TLS WebSocket.
          #
          # @param [String] host
          #   The WebSocket host.
          #
          # @param [Integer] port
          #   The WebSocket port.
          #
          # @param [Hash{Symbol => Object}] ssl
          #   Additional keyword arguments for
          #   `Ronin::Support::Network::SSL.connect`.
          #
          # @param [Hash{Symbol => Object}] kwargs
          #   Additional keyword arguments for {Client#initialize}.
          #
          # @!macro client_kwargs
          #
          # @yield [websocket]
          #   If a block is given, then it will be passed the WebSocket
          #   connection. Once the block has returned, the WebSocket connection
          #   will be closed.
          #
          # @yieldparam [Client] websocket
          #   The WebSocket connection.
          #
          # @return [Client]
          #   The WebSocket connection.
          #
          # @example Connecting to a WebSocket server:
          #   wss_connect('websocket-echo.com')
          #   # => #<Ronin::Support::Web::WebSocket::Client: ...>
          #
          # @example Creating a temporary WebSocket connection:
          #   wss_connect('websocket-echo.com') do |websocket|
          #     # ...
          #   end
          #
          # @api public
          #
          def wss_connect(host,port=443, ssl: {}, **kwargs,&block)
            uri = URI::WSS.build(host: host, port: port)

            websocket_connect(uri, ssl: ssl, **kwargs,&block)
          end

          # @!macro [new] server_kwargs
          #   @option kwargs [String, nil] :bind_host
          #     The optional host to bind the server socket to.
          #
          #   @option kwargs [Integer, nil] :bind_port
          #     The optioanl port to bind the server socket to. If not
          #     specified, it will default to the port of the URL.
          #
          #   @option kwargs [Integer] :backlog (5)
          #     The maximum backlog of pending connections.
          #
          #   @!macro ssl_kwargs

          #
          # Starts a WebSocket server.
          #
          # @param [String, URI::WS, URI::WSS] url
          #   The `ws://` or `wss://` URL to connect to.
          #
          # @param [Hash{Symbol => Object}] ssl
          #   Additional keyword arguments for
          #   `Ronin::Support::Network::SSL.server`.
          #
          # @param [Hash{Symbol => Object}] kwargs
          #   Additional keyword arguments for {Server#initialize}.
          #
          # @!macro server_kwargs
          #
          # @yield [server]
          #   If a block is given, then it will be passed the WebSocket server.
          #   Once the block has returned, the WebSocket server will be closed.
          #
          # @yieldparam [Server] server
          #   The WebSocket server.
          #
          # @return [Server]
          #   The WebSocket server.
          #
          # @api public
          #
          def websocket_server(url, ssl: {}, **kwargs,&block)
            server = Server.new(url, ssl: ssl, **kwargs)

            if block_given?
              yield server
              server.close
            else
              server
            end
          end

          #
          # Creates a new WebSocket server listening on a given host and port,
          # accepting clients in a loop.
          #
          # @param [String, URI::WS, URI::WSS] url
          #   The `ws://` or `wss://` URL to connect to.
          #
          # @param [Hash{Symbol => Object}] ssl
          #   Additional keyword arguments for
          #   `Ronin::Support::Network::SSL.server`.
          #
          # @param [Hash{Symbol => Object}] kwargs
          #   Additional keyword arguments for {Server#initialize}.
          #
          # @!macro server_kwargs
          #
          # @yield [client]
          #   The given block will be passed the newly connected WebSocket
          #   client. After the block has finished, the WebSocket client will be
          #   closed.
          #
          # @yieldparam [Server::Client] client
          #   A newly connected WebSocket client.
          #
          # @return [nil]
          #
          def websocket_server_loop(url, ssl: {}, **kwargs)
            websocket_server(url, ssl: ssl, **kwargs) do |server|
              loop do
                client = server.accept
                yield client if block_given?
                client.close
              end
            end
          end

          #
          # Starts a WebSocket server.
          #
          # @param [String, nil] host
          #   The optional host that the WebSocket server will listen on.
          #
          # @param [Integer, nil] port
          #   The optional port that the WebSocket server will listen on.
          #
          # @param [Hash{Symbol => Object}] kwargs
          #   Additional keyword arguments for {Server#initialize}.
          #
          # @param [Hash{Symbol => Object}] ssl
          #   Additional keyword arguments for
          #   `Ronin::Support::Network::SSL.server`.
          #
          # @!macro server_kwargs
          #
          # @yield [server]
          #   If a block is given, then it will be passed the WebSocket server.
          #   Once the block has returned, the WebSocket server will be closed.
          #
          # @yieldparam [Server] server
          #   The WebSocket server.
          #
          # @return [Server]
          #   The WebSocket server.
          #
          # @api public
          #
          def ws_server(host,port=80, ssl: {}, **kwargs,&block)
            uri = URI::WS.build(host: host, port: port)

            websocket_server(uri, ssl: ssl, **kwargs,&block)
          end

          #
          # Starts a SSL/TLS WebSocket server.
          #
          # @param [String, nil] host
          #   The optional host that the WebSocket server will listen on.
          #
          # @param [Integer, nil] port
          #   The optional port that the WebSocket server will listen on.
          #
          # @param [Hash{Symbol => Object}] kwargs
          #   Additional keyword arguments for {Server#initialize}.
          #
          # @param [Hash{Symbol => Object}] ssl
          #   Additional keyword arguments for
          #   `Ronin::Support::Network::SSL.server`.
          #
          # @!macro server_kwargs
          #
          # @yield [server]
          #   If a block is given, then it will be passed the WebSocket server.
          #   Once the block has returned, the WebSocket server will be closed.
          #
          # @yieldparam [Server] server
          #   The WebSocket server.
          #
          # @return [Server]
          #   The WebSocket server.
          #
          # @api public
          #
          def wss_server(host,port=443, ssl: {}, **kwargs,&block)
            uri = URI::WSS.build(host: host, port: port)

            websocket_server(uri, ssl: ssl, **kwargs,&block)
          end
        end
      end
    end
  end
end
