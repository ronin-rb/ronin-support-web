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

require_relative '../websocket'

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

          #
          # Tests whether the WebSocket is open.
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
          # @return [Boolean, nil]
          #   Specifies whether the WebSocket is open.
          #   If the connection was not accepted, `nil` will be returned.
          #
          # @api public
          #
          # @see WebSocket.open?
          #
          def websocket_open?(url, ssl: {}, **kwargs)
            WebSocket.open?(url, ssl: ssl, **kwargs)
          end

          #
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
          # @see WebSocket.connect
          #
          def websocket_connect(url, ssl: {}, **kwargs, &block)
            WebSocket.connect(url, ssl: ssl, **kwargs, &block)
          end

          #
          # Connects to the WebSocket and sends the data.
          #
          # @param [String] data
          #   The data to send to the WebSocket.
          #
          # @param [String, URI::WS, URI::WSS] url
          #   The `ws://` or `wss://` URL to connect to.
          #
          # @param [:text, :binary, :ping, :pong, :close] type
          #   The data frame type.
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
          # @api public
          #
          # @see WebSocket.connect_and_send
          #
          def websocket_connect_and_send(data,url, type: :text, ssl: {}, **kwargs,&block)
            WebSocket.connect_and_send(data,url, type: type, ssl: ssl, **kwargs,&block)
          end

          #
          # Connects to the WebSocket, sends the data, and closes the
          # connection.
          #
          # @param [String] data
          #   The data to send to the WebSocket.
          #
          # @param [String, URI::WS, URI::WSS] url
          #   The `ws://` or `wss://` URL to connect to.
          #
          # @param [:text, :binary, :ping, :pong, :close] type
          #   The data frame type.
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
          # @return [true]
          #
          # @api public
          #
          # @see WebSocket.send
          #
          def websocket_send(data,url, type: :text, ssl: {}, **kwargs)
            WebSocket.send(data,url, type: type, ssl: ssl, **kwargs)
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
          # @see WebSocket.server
          #
          def websocket_server(url, ssl: {}, **kwargs, &block)
            WebSocket.server(url, ssl: ssl, **kwargs, &block)
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
          # @api public
          #
          # @see WebSocket.server_loop
          #
          def websocket_server_loop(url, ssl: {}, **kwargs,&block)
            WebSocket.server_loop(url, ssl: ssl, **kwargs,&block)
          end

          #
          # Opens a WebSocket server, accepts a single connection, yields it to
          # the given block, then closes both the connection and the server.
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
          # @api public
          #
          # @see WebSocket.accept
          #
          def websocket_accept(url, ssl: {}, **kwargs,&block)
            WebSocket.accept(url, ssl: ssl, **kwargs,&block)
          end

          #
          # Tests whether the WebSocket is open.
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
          # @return [Boolean, nil]
          #   Specifies whether the WebSocket is open.
          #   If the connection was not accepted, `nil` will be returned.
          #
          # @api public
          #
          # @see WebSocket.open?
          #
          def ws_open?(host,port=80, ssl: {}, **kwargs)
            uri = URI::WS.build(host: host, port: port)

            WebSocket.open?(uri, ssl: ssl, **kwargs)
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
          # @see WebSocket.connect
          #
          def ws_connect(host,port=80, ssl: {}, **kwargs,&block)
            uri = URI::WS.build(host: host, port: port)

            WebSocket.connect(uri, ssl: ssl, **kwargs, &block)
          end

          #
          # Connects to the WebSocket and sends the data.
          #
          # @param [String] data
          #   The data to send to the WebSocket.
          #
          # @param [String] host
          #   The WebSocket host.
          #
          # @param [Integer] port
          #   The WebSocket port.
          #
          # @param [:text, :binary, :ping, :pong, :close] type
          #   The data frame type.
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
          # @api public
          #
          # @see WebSocket.connect_and_send
          #
          def ws_connect_and_send(data,host,port=80, type: :text, ssl: {}, **kwargs,&block)
            uri = URI::WS.build(host: host, port: port)

            WebSocket.connect_and_send(data,uri, type: type, ssl: ssl, **kwargs,&block)
          end

          #
          # Connects to the WebSocket, sends the data, and closes the
          # connection.
          #
          # @param [String] data
          #   The data to send to the WebSocket.
          #
          # @param [String] host
          #   The WebSocket host.
          #
          # @param [Integer] port
          #   The WebSocket port.
          #
          # @param [:text, :binary, :ping, :pong, :close] type
          #   The data frame type.
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
          # @return [true]
          #
          # @api public
          #
          # @see WebSocket.send
          #
          def ws_send(data,host,port=80, type: :text, ssl: {}, **kwargs)
            uri = URI::WS.build(host: host, port: port)

            WebSocket.send(data,uri, type: type, ssl: ssl, **kwargs)
          end

          #
          # Tests whether the SSL/TLS WebSocket is open.
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
          # @return [Boolean, nil]
          #   Specifies whether the WebSocket is open.
          #   If the connection was not accepted, `nil` will be returned.
          #
          # @api public
          #
          # @see WebSocket.open?
          #
          def wss_open?(host,port=443, ssl: {}, **kwargs)
            uri = URI::WSS.build(host: host, port: port)

            WebSocket.open?(uri, ssl: ssl, **kwargs)
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
          # @see WebSocket.connect
          #
          def wss_connect(host,port=443, ssl: {}, **kwargs,&block)
            uri = URI::WSS.build(host: host, port: port)

            WebSocket.connect(uri, ssl: ssl, **kwargs, &block)
          end

          #
          # Connects to the SSL/TLS WebSocket and sends the data.
          #
          # @param [String] data
          #   The data to send to the WebSocket.
          #
          # @param [String] host
          #   The WebSocket host.
          #
          # @param [Integer] port
          #   The WebSocket port.
          #
          # @param [:text, :binary, :ping, :pong, :close] type
          #   The data frame type.
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
          # @api public
          #
          # @see WebSocket.connect_and_send
          #
          def wss_connect_and_send(data,host,port=443, type: :text, ssl: {}, **kwargs,&block)
            uri = URI::WSS.build(host: host, port: port)

            WebSocket.connect_and_send(data,uri, type: type, ssl: ssl, **kwargs, &block)
          end

          #
          # Connects to the SSL/TLS WebSocket, sends the data, and closes the
          # connection.
          #
          # @param [String] data
          #   The data to send to the WebSocket.
          #
          # @param [String] host
          #   The WebSocket host.
          #
          # @param [Integer] port
          #   The WebSocket port.
          #
          # @param [:text, :binary, :ping, :pong, :close] type
          #   The data frame type.
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
          # @return [true]
          #
          # @api public
          #
          # @see WebSocket.send
          #
          def wss_send(data,host,port=443, type: :text, ssl: {}, **kwargs)
            uri = URI::WSS.build(host: host, port: port)

            WebSocket.send(data,uri, type: type, ssl: ssl, **kwargs)
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
          # @see WebSocker.server
          #
          def ws_server(host,port=80, ssl: {}, **kwargs,&block)
            uri = URI::WS.build(host: host, port: port)

            WebSocket.server(uri, ssl: ssl, **kwargs,&block)
          end

          #
          # Creates a new WebSocket server listening on a given host and port,
          # accepting clients in a loop.
          #
          # @param [String, nil] host
          #   The optional host that the WebSocket server will listen on.
          #
          # @param [Integer, nil] port
          #   The optional port that the WebSocket server will listen on.
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
          # @api public
          #
          # @see WebSocket.server_loop
          #
          def ws_server_loop(host,port=80, ssl: {}, **kwargs,&block)
            uri = URI::WS.build(host: host, port: port)

            WebSocket.server_loop(uri, ssl: ssl, **kwargs,&block)
          end

          #
          # Opens a WebSocket server, accepts a single connection, yields it to
          # the given block, then closes both the connection and the server.
          #
          # @param [String, nil] host
          #   The optional host that the WebSocket server will listen on.
          #
          # @param [Integer, nil] port
          #   The optional port that the WebSocket server will listen on.
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
          # @api public
          #
          # @see WebSocket.accept
          #
          def ws_accept(host,port=80, ssl: {}, **kwargs,&block)
            uri = URI::WS.build(host: host, port: port)

            WebSocket.accept(uri, ssl: ssl, **kwargs,&block)
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
          # @see WebSocket.server
          #
          def wss_server(host,port=443, ssl: {}, **kwargs,&block)
            uri = URI::WSS.build(host: host, port: port)

            WebSocket.server(uri, ssl: ssl, **kwargs,&block)
          end

          #
          # Creates a new SSL/TLS WebSocket server listening on a given host
          # and port, accepting clients in a loop.
          #
          # @param [String, nil] host
          #   The optional host that the WebSocket server will listen on.
          #
          # @param [Integer, nil] port
          #   The optional port that the WebSocket server will listen on.
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
          # @api public
          #
          # @see WebSocket.server_loop
          #
          def wss_server_loop(host,port=443, ssl: {}, **kwargs,&block)
            uri = URI::WSS.build(host: host, port: port)

            WebSocket.server_loop(uri, ssl: ssl, **kwargs,&block)
          end

          #
          # Opens a SSL/TLS WebSocket server, accepts a single connection,
          # yields it to the given block, then closes both the connection and
          # the server.
          #
          # @param [String, nil] host
          #   The optional host that the WebSocket server will listen on.
          #
          # @param [Integer, nil] port
          #   The optional port that the WebSocket server will listen on.
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
          # @api public
          #
          # @see WebSocket.accept
          #
          def wss_accept(host,port=443, ssl: {}, **kwargs,&block)
            uri = URI::WSS.build(host: host, port: port)

            WebSocket.accept(uri, ssl: ssl, **kwargs,&block)
          end
        end
      end
    end
  end
end
