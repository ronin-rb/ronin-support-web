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

require 'ronin/support/network/http'

require 'addressable/uri'
require 'nokogiri'
require 'json'

module Ronin
  module Support
    module Web
      #
      # Web Agent represents a stripped-down web browser, which can request
      # URLs, follow redirects, and parse responses.
      #
      # ## Features
      #
      # * Automatically follows redirects.
      # * Provides low-level HTTP methods.
      # * Provides high-level methods for requesting and parsing HTML, XML, or
      #   JSON.
      # * Maintains a persistent connection pool.
      #
      # ## Anti-Features
      #
      # * Does not cache files or write to the disk.
      # * Does not evaluate JavaScript.
      #
      class Agent

        #
        # Base-class for all {Agent} exceptions.
        #
        class Error < RuntimeError
        end

        #
        # Indicates that too many redirects were encountered in succession.
        #
        class TooManyRedirects < Error
        end

        #
        # Indicates that the response does not have a compatible or expected
        # `Content-Type` header.
        #
        class ContentTypeError < Error
        end

        # The proxy to send requests through.
        #
        # @return [URI::HTTP, Addressable::URI, nil]
        attr_reader :proxy

        # The `User-Agent` header value.
        #
        # @return [String, nil]
        attr_reader :user_agent

        # Maximum number of redirects to follow.
        #
        # @return [Integer]
        attr_reader :max_redirects

        #
        # Initializes the Web agent.
        #
        # @param [Boolean] follow_redirects
        #   Specifies whether HTTP redirects will automatically be followed.
        #
        # @param [Integer] max_redirects
        #   The maximum number of redirects to follow. Defaults to 20.
        #
        # @param [String, URI::HTTP, Addressable::URI, nil] proxy
        #   The optional proxy to send requests through.
        #
        # @param [String, :random, :chrome, :chrome_linux, :chrome_macos, :chrome_windows, :chrome_iphone, :chrome_ipad, :chrome_android, :firefox, :firefox_linux, :firefox_macos, :firefox_windows, :firefox_iphone, :firefox_ipad, :firefox_android, :safari, :safari_macos, :safari_iphone, :safari_ipad, :edge, :linux, :macos, :windows, :iphone, :ipad, :android, nil] user_agent
        #   The default `User-Agent` string to add to each request.
        #
        # @param [Boolean, Hash{Symbol => Object}, nil] ssl
        #   Additional SSL/TLS configuration.
        #
        # @option ssl [String, nil] :ca_bundle
        #   The path to the CA bundle directory or file.
        #
        # @option ssl [OpenSSL::X509::Store, nil] :cert_store
        #   The certificate store to use for the SSL/TLS connection.
        #
        # @option ssl [Array<(name, version, bits, alg_bits)>, nil] :ciphers
        #   The accepted ciphers to use for the SSL/TLS connection.
        #
        # @option ssl [Integer, nil] :timeout
        #   The connection timeout limit.
        #
        # @option ssl [1, 1.1, 1.2, Symbol, nil] :version
        #   The desired SSL/TLS version.
        #
        # @option ssl [1, 1.1, 1.2, Symbol, nil] :min_version
        #   The minimum SSL/TLS version.
        #
        # @option ssl [1, 1.1, 1.2, Symbol, nil] :max_version
        #   The maximum SSL/TLS version.
        #
        # @option ssl [Proc, nil] :verify_callback
        #   The callback to use when verifying the server's certificate.
        #
        # @option ssl [Integer, nil] :verify_depth
        #   The verification depth limit.
        #
        # @option ssl [:none, :peer, :fail_if_no_peer_cert, true, false, Integer, nil] :verify
        #   The verification mode.
        #
        # @option ssl [Boolean, nil] :verify_hostname
        #   Indicates whether to verify the server's hostname.
        #
        def initialize(follow_redirects: true,
                       max_redirects:    20,
                       # HTTP options
                       proxy:      Support::Network::HTTP.proxy,
                       ssl:        nil,
                       user_agent: Support::Network::HTTP.user_agent)
          @follow_redirects = follow_redirects
          @max_redirects    = max_redirects

          # HTTP options
          @proxy      = proxy
          @ssl        = ssl
          @user_agent = user_agent

          @sessions = {}
        end

        #
        # Indicates whether redirects will automatically be followed.
        #
        # @return [Boolean]
        #
        def follow_redirects?
          @follow_redirects
        end

        #
        # @!macro request_kwargs
        #   @option kwargs [String, nil] :query
        #     The query-string to append to the request path.
        #
        #   @option kwargs [Hash, nil] :query_params
        #     The query-params to append to the request path.
        #
        #   @option kwargs [String, nil] :user
        #     The user to authenticate as.
        #
        #   @option kwargs [String, nil] :password
        #     The password to authenticate with.
        #
        #   @option kwargs [Hash{Symbol,String => String}, nil] :headers
        #     Additional HTTP headers to use for the request.
        #
        #   @option kwargs [String, :text, :xml, :html, :json, nil] :content_type
        #     The `Content-Type` header value for the request.
        #     If a Symbol is given it will be resolved to a common MIME type:
        #     * `:text` - `text/plain`
        #     * `:xml` - `text/xml`
        #     * `:html` - `text/html`
        #     * `:json` - `application/json`
        #
        #   @option kwargs [String, :text, :xml, :html, :json, nil] :accept
        #     The `Accept` header value for the request.
        #     If a Symbol is given it will be resolved to a common MIME type:
        #     * `:text` - `text/plain`
        #     * `:xml` - `text/xml`
        #     * `:html` - `text/html`
        #     * `:json` - `application/json`
        #
        #   @option kwargs [String, Hash{String => String}, Ronin::Support::Network::HTTP::Cookie, nil] :cookie
        #     Additional `Cookie` header.
        #     * If a `Hash` is given, it will be converted to a `String` using
        #       [Ronin::Support::Network::HTTP::Cookie](https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP/Cookie.html).
        #     * If the cookie value is empty, the `Cookie` header will not be
        #     set.
        #
        #   @option kwargs [String, nil] :body
        #     The body of the request.
        #
        #   @option kwargs [Hash, String, nil] :form_data
        #     The form data that may be sent in the body of the request.
        #
        #   @option kwargs [#to_json, nil] :json
        #     The JSON data that will be sent in the body of the request.
        #     Will also default the `Content-Type` header to
        #     `application/json`, unless already set.
        #

        #
        # Performs and arbitrary HTTP request.
        #
        # @param [Symbol, String] method
        #   The HTTP method to use for the request.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @yield [response]
        #   If a block is given it will be passed the received HTTP response.
        #
        # @yieldparam [Net::HTTPResponse] response
        #   The received HTTP response object.
        #
        # @return [Net::HTTPResponse]
        #   The HTTP response object.
        #
        # @raise [ArgumentError]
        #   The `:method` option did not match a known `Net::HTTP` request
        #   class.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#request-instance_method
        #
        # @api public
        #
        def http_request(method,url,**kwargs,&block)
          uri = normalize_url(url)

          session_for(uri).request(
            method, uri.request_uri, user:     uri.user,
                                     password: uri.password,
                                     **kwargs, &block
          )
        end

        #
        # Sends an arbitrary HTTP request and returns the response status.
        #
        # @param [Symbol, String] method
        #   The HTTP method to use for the request.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @return [Integer]
        #   The status code of the response.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#response_status-instance_method
        #
        # @api public
        #
        def http_response_status(method=:head,url,**kwargs)
          uri = normalize_url(url)

          session_for(uri).response_status(
            method, uri.request_uri, user:     uri.user,
                                     password: uri.password,
                                     **kwargs
          )
        end

        #
        # Sends a HTTP request and determines if the response status was 200.
        #
        # @param [Symbol, String] method
        #   The HTTP method to use for the request.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @return [Boolean]
        #   Indicates that the response status was 200.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#ok%3F-instance_method
        #
        # @api public
        #
        def http_ok?(method=:head,url,**kwargs)
          uri = normalize_url(url)

          session_for(uri).ok?(
            method, uri.request_uri, user:     uri.user,
                                     password: uri.password,
                                     **kwargs
          )
        end

        #
        # Sends an arbitrary HTTP request and returns the response headers.
        #
        # @param [Symbol, String] method
        #   The HTTP method to use for the request.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @return [Hash{String => String}]
        #   The response headers.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#response_headers-instance_method
        #
        # @api public
        #
        def http_response_headers(method=:head,url,**kwargs)
          uri = normalize_url(url)

          session_for(uri).response_headers(
            method, uri.request_uri, user:     uri.user,
                                     password: uri.password,
                                     **kwargs
          )
        end

        #
        # Sends an HTTP request and returns the `Server` header.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @return [String, nil]
        #   The `Server` header.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#server_header-instance_method
        #
        # @api public
        #
        def http_server_header(url,**kwargs)
          uri = normalize_url(url)

          session_for(uri).server_header(
            user:     uri.user,
            password: uri.password,
            path:     uri.request_uri,
            **kwargs
          )
        end

        #
        # Sends an HTTP request and returns the `X-Powered-By` header.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @return [String, nil]
        #   The `X-Powered-By` header.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#powered_by_header-instance_method
        #
        # @api public
        #
        def http_powered_by_header(url,**kwargs)
          uri = normalize_url(url)

          session_for(uri).powered_by_header(
            user:     uri.user,
            password: uri.password,
            path:     uri.request_uri,
            **kwargs
          )
        end

        #
        # Sends an arbitrary HTTP request and returns the response body.
        #
        # @param [Symbol, String] method
        #   The HTTP method to use for the request.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @return [String]
        #   The response body.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#response_body-instance_method
        #
        # @api public
        #
        def http_response_body(method=:get,url,**kwargs)
          uri = normalize_url(url)

          session_for(uri).response_body(
            method, uri.request_uri, user:     uri.user,
                                     password: uri.password,
                                     **kwargs
          )
        end

        #
        # Performs a `COPY` request for the given URI.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @yield [response]
        #   If a block is given it will be passed the received HTTP response.
        #
        # @yieldparam [Net::HTTPResponse] response
        #   The received HTTP response object.
        #
        # @return [Net::HTTPResponse]
        #   The HTTP response object.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#copy-instance_method
        #
        # @api public
        #
        def http_copy(url,**kwargs,&block)
          uri = normalize_url(url)

          session_for(uri).copy(
            uri.request_uri, user:     uri.user,
                             password: uri.password,
                             **kwargs, &block
          )
        end

        #
        # Performs a `DELETE` request for the given URI.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @yield [response]
        #   If a block is given it will be passed the received HTTP response.
        #
        # @yieldparam [Net::HTTPResponse] response
        #   The received HTTP response object.
        #
        # @return [Net::HTTPResponse]
        #   The HTTP response object.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#delete-instance_method
        #
        # @api public
        #
        def http_delete(url,**kwargs,&block)
          uri = normalize_url(url)

          session_for(uri).delete(
            uri.request_uri, user:     uri.user,
                             password: uri.password,
                             **kwargs, &block
          )
        end

        #
        # Performs a `GET` request for the given URI.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @yield [response]
        #   If a block is given it will be passed the received HTTP response.
        #
        # @yieldparam [Net::HTTPResponse] response
        #   The received HTTP response object.
        #
        # @return [Net::HTTPResponse]
        #   The HTTP response object.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#get-instance_method
        #
        # @api public
        #
        def http_get(url,**kwargs,&block)
          uri = normalize_url(url)

          session_for(uri).get(
            uri.request_uri, user:     uri.user,
                             password: uri.password,
                             **kwargs, &block
          )
        end

        #
        # Performs a `GET` request for the given URI and returns the response
        # headers.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @return [Hash{String => String}]
        #   The response headers.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#get_headers-instance_method
        #
        # @api public
        #
        def http_get_headers(url,**kwargs)
          uri = normalize_url(url)

          session_for(uri).get_headers(
            uri.request_uri, user:     uri.user,
                             password: uri.password,
                             **kwargs
          )
        end

        #
        # Sends an HTTP request and returns the parsed `Set-Cookie`
        # header(s).
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @return [Array<SetCookie>, nil]
        #   The parsed `SetCookie` header(s).
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#get_cookies-instance_method
        #
        # @api public
        #
        def http_get_cookies(url,**kwargs)
          uri = normalize_url(url)

          session_for(uri).get_cookies(
            uri.request_uri, user:     uri.user,
                             password: uri.password,
                             **kwargs
          )
        end

        #
        # Performs a `GET` request for the given URI and returns the response
        # body.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @return [String]
        #   The response body.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#get_body-instance_method
        #
        # @api public
        #
        def http_get_body(url,**kwargs)
          uri = normalize_url(url)

          session_for(uri).get_body(
            uri.request_uri, user:     uri.user,
                             password: uri.password,
                             **kwargs
          )
        end

        #
        # Performs a `HEAD` request for the given URI.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @yield [response]
        #   If a block is given it will be passed the received HTTP response.
        #
        # @yieldparam [Net::HTTPResponse] response
        #   The received HTTP response object.
        #
        # @return [Net::HTTPResponse]
        #   The HTTP response object.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#head-instance_method
        #
        # @api public
        #
        def http_head(url,**kwargs,&block)
          uri = normalize_url(url)

          session_for(uri).head(
            uri.request_uri, user:     uri.user,
                             password: uri.password,
                             **kwargs, &block
          )
        end

        #
        # Performs a `LOCK` request for the given URI.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @yield [response]
        #   If a block is given it will be passed the received HTTP response.
        #
        # @yieldparam [Net::HTTPResponse] response
        #   The received HTTP response object.
        #
        # @return [Net::HTTPResponse]
        #   The HTTP response object.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#lock-instance_method
        #
        # @api public
        #
        def http_lock(url,**kwargs,&block)
          uri = normalize_url(url)

          session_for(uri).lock(
            uri.request_uri, user:     uri.user,
                             password: uri.password,
                             **kwargs, &block
          )
        end

        #
        # Performs a `MKCOL` request for the given URI.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @yield [response]
        #   If a block is given it will be passed the received HTTP response.
        #
        # @yieldparam [Net::HTTPResponse] response
        #   The received HTTP response object.
        #
        # @return [Net::HTTPResponse]
        #   The HTTP response object.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#mkcol-instance_method
        #
        # @api public
        #
        def http_mkcol(url,**kwargs,&block)
          uri = normalize_url(url)

          session_for(uri).mkcol(
            uri.request_uri, user:     uri.user,
                             password: uri.password,
                             **kwargs, &block
          )
        end

        #
        # Performs a `MOVE` request for the given URI.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @yield [response]
        #   If a block is given it will be passed the received HTTP response.
        #
        # @yieldparam [Net::HTTPResponse] response
        #   The received HTTP response object.
        #
        # @return [Net::HTTPResponse]
        #   The HTTP response object.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#move-instance_method
        #
        # @api public
        #
        def http_move(url,**kwargs,&block)
          uri = normalize_url(url)

          session_for(uri).move(
            uri.request_uri, user:     uri.user,
                             password: uri.password,
                             **kwargs, &block
          )
        end

        #
        # Performs a `OPTIONS` request for the given URI.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @yield [response]
        #   If a block is given it will be passed the received HTTP response.
        #
        # @yieldparam [Net::HTTPResponse] response
        #   The received HTTP response object.
        #
        # @return [Net::HTTPResponse]
        #   The HTTP response object.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#options-instance_method
        #
        # @api public
        #
        def http_options(url,**kwargs,&block)
          uri = normalize_url(url)

          session_for(uri).options(
            uri.request_uri, user:     uri.user,
                             password: uri.password,
                             **kwargs, &block
          )
        end

        #
        # Performs a `OPTIONS` HTTP request for the given URI and parses the
        # `Allow` response header.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @return [Array<Symbol>]
        #   The allowed HTTP request methods for the given URL.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#allowed_methods-instance_method
        #
        # @api public
        #
        def http_allowed_methods(url,**kwargs)
          uri = normalize_url(url)

          session_for(uri).allowed_methods(
            uri.request_uri, user:     uri.user,
                             password: uri.password,
                             **kwargs
          )
        end

        #
        # Performs a `PATCH` request for the given URI.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @yield [response]
        #   If a block is given it will be passed the received HTTP response.
        #
        # @yieldparam [Net::HTTPResponse] response
        #   The received HTTP response object.
        #
        # @return [Net::HTTPResponse]
        #   The HTTP response object.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#patch-instance_method
        #
        # @api public
        #
        def http_patch(url,**kwargs,&block)
          uri = normalize_url(url)

          session_for(uri).patch(
            uri.request_uri, user:     uri.user,
                             password: uri.password,
                             **kwargs, &block
          )
        end

        #
        # Performs a `POST` request for the given URI.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @yield [response]
        #   If a block is given it will be passed the received HTTP response.
        #
        # @yieldparam [Net::HTTPResponse] response
        #   The received HTTP response object.
        #
        # @return [Net::HTTPResponse]
        #   The HTTP response object.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#post-instance_method
        #
        # @api public
        #
        def http_post(url,**kwargs,&block)
          uri = normalize_url(url)

          session_for(uri).post(
            uri.request_uri, user:     uri.user,
                             password: uri.password,
                             **kwargs, &block
          )
        end

        #
        # Performs a `POST` request on the given URI and returns the response
        # headers.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @return [Hash{String => String}]
        #   The response headers.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#post_headers-instance_method
        #
        # @api public
        #
        def http_post_headers(url,**kwargs)
          uri = normalize_url(url)

          session_for(uri).post_headers(
            uri.request_uri, user:     uri.user,
                             password: uri.password,
                             **kwargs
          )
        end

        #
        # Performs a `POST` request for the given URI and returns the
        # response body.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @return [String]
        #   The response body.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#post_body-instance_method
        #
        # @api public
        #
        def http_post_body(url,**kwargs)
          uri = normalize_url(url)

          session_for(uri).post_body(
            uri.request_uri, user:     uri.user,
                             password: uri.password,
                             **kwargs
          )
        end

        #
        # Performs a `PROPFIND` request for the given URI.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @yield [response]
        #   If a block is given it will be passed the received HTTP response.
        #
        # @yieldparam [Net::HTTPResponse] response
        #   The received HTTP response object.
        #
        # @return [Net::HTTPResponse]
        #   The HTTP response object.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#propfind-instance_method
        #
        # @api public
        #
        def http_propfind(url,**kwargs,&block)
          uri = normalize_url(url)

          session_for(uri).propfind(
            uri.request_uri, user:     uri.user,
                             password: uri.password,
                             **kwargs, &block
          )
        end

        alias http_prop_find http_propfind

        #
        # Performs a `PROPPATCH` request for the given URI.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @yield [response]
        #   If a block is given it will be passed the received HTTP response.
        #
        # @yieldparam [Net::HTTPResponse] response
        #   The received HTTP response object.
        #
        # @return [Net::HTTPResponse]
        #   The HTTP response object.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#proppatch-instance_method
        #
        # @api public
        #
        def http_proppatch(url,**kwargs,&block)
          uri = normalize_url(url)

          session_for(uri).proppatch(
            uri.request_uri, user:     uri.user,
                             password: uri.password,
                             **kwargs, &block
          )
        end

        alias http_prop_patch http_proppatch

        #
        # Performs a `PUT` request for the given URI.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @yield [response]
        #   If a block is given it will be passed the received HTTP response.
        #
        # @yieldparam [Net::HTTPResponse] response
        #   The received HTTP response object.
        #
        # @return [Net::HTTPResponse]
        #   The HTTP response object.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#put-instance_method
        #
        # @api public
        #
        def http_put(url,**kwargs,&block)
          uri = normalize_url(url)

          session_for(uri).put(
            uri.request_uri, user:     uri.user,
                             password: uri.password,
                             **kwargs, &block
          )
        end

        #
        # Performs a `TRACE` request for the given URI.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @yield [response]
        #   If a block is given it will be passed the received HTTP response.
        #
        # @yieldparam [Net::HTTPResponse] response
        #   The received HTTP response object.
        #
        # @return [Net::HTTPResponse]
        #   The HTTP response object.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#trace-instance_method
        #
        # @api public
        #
        def http_trace(url,**kwargs,&block)
          uri = normalize_url(url)

          session_for(uri).trace(
            uri.request_uri, user:     uri.user,
                             password: uri.password,
                             **kwargs, &block
          )
        end

        #
        # Performs a `UNLOCK` request for the given URI.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP request for.
        #
        # @!macro request_kwargs
        #
        # @yield [response]
        #   If a block is given it will be passed the received HTTP response.
        #
        # @yieldparam [Net::HTTPResponse] response
        #   The received HTTP response object.
        #
        # @return [Net::HTTPResponse]
        #   The HTTP response object.
        #
        # @see https://ronin-rb.dev/docs/ronin-support/Ronin/Support/Network/HTTP.html#unlock-instance_method
        #
        # @api public
        #
        def http_unlock(url,**kwargs,&block)
          uri = normalize_url(url)

          session_for(uri).unlock(
            uri.request_uri, user:     uri.user,
                             password: uri.password,
                             **kwargs, &block
          )
        end

        #
        # Gets a URL and returns the response.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP GET request for.
        #
        # @param [Boolean] follow_redirects
        #   Overrides whether HTTP redirects will automatically be followed.
        #
        # @param [Integer] max_redirects
        #   Overrides the maximum number of redirects to follow.
        #
        # @!macro request_kwargs
        #
        # @yield [response]
        #   If a block is given it will be passed the received HTTP response.
        #
        # @yieldparam [Net::HTTPResponse] response
        #   The received HTTP response object.
        #
        # @return [Net::HTTPResponse]
        #   The HTTP response object.
        #
        # @raise [TooManyRedirects]
        #   Maximum number of redirects reached.
        #
        # @note This method will follow redirects by default.
        #
        # @example
        #   response = agent.get('https://example.com/')
        #   # => #<Net::HTTPResponse:...>
        #
        def get(url, follow_redirects: @follow_redirects,
                     max_redirects:    @max_redirects,
                     **kwargs)
          response = http_get(url,**kwargs)

          if follow_redirects && response.kind_of?(Net::HTTPRedirection)
            redirect_count = 0

            while response.kind_of?(Net::HTTPRedirection)
              if redirect_count >= max_redirects
                raise(TooManyRedirects,"maximum number of redirects reached: #{url.inspect}")
              end

              location = response['Location']
              response = http_get(location)

              redirect_count += 1
            end
          end

          yield response if block_given?
          return response
        end

        #
        # Gets the URL and returns the parsed HTML.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP GET request for.
        #
        # @option kwargs [Boolean] :follow_redirects
        #   Overrides whether HTTP redirects will automatically be followed.
        #
        # @option kwargs [Integer] :max_redirects
        #   Overrides the maximum number of redirects to follow.
        #
        # @!macro request_kwargs
        #
        # @return [Nokogiri::HTML::Document]
        #   The parsed HTML response.
        #
        # @raise [ContentTypeError]
        #   Did not receive a response with a `Content-Type` of `text/html`.
        #
        # @raise [TooManyRedirects]
        #   Maximum number of redirects reached.
        #
        # @note This method will follow redirects by default.
        #
        # @example
        #   doc = agent.get_html('https://example.com/page.html')
        #   # => #<Nokogiri::HTML::Document:...>
        #
        def get_html(url,**kwargs)
          response = get(url,**kwargs)

          unless response.content_type.include?('text/html')
            raise(ContentTypeError,"response 'Content-Type' was not 'text/html': #{response.content_type.inspect}")
          end

          return Nokogiri::HTML(response.body)
        end

        #
        # Gets the URL and returns the parsed XML.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP GET request for.
        #
        # @option kwargs [Boolean] :follow_redirects
        #   Overrides whether HTTP redirects will automatically be followed.
        #
        # @option kwargs [Integer] :max_redirects
        #   Overrides the maximum number of redirects to follow.
        #
        # @!macro request_kwargs
        #
        # @return [Nokogiri::XML::Document]
        #   The parsed XML response.
        #
        # @raise [ContentTypeError]
        #   Did not receive a response with a `Content-Type` of `text/xml`.
        #
        # @raise [TooManyRedirects]
        #   Maximum number of redirects reached.
        #
        # @note This method will follow redirects by default.
        #
        # @example
        #   doc = agent.get_xml('https://example.com/data.xml')
        #   # => #<Nokogiri::XML::Document:...>
        #
        def get_xml(url,**kwargs)
          response = get(url,**kwargs)

          unless response.content_type.include?('text/xml')
            raise(ContentTypeError,"response 'Content-Type' was not 'text/xml': #{response.content_type.inspect}")
          end

          return Nokogiri::XML(response.body)
        end

        #
        # Gets the URL and returns the parsed JSON.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP GET request for.
        #
        # @option kwargs [Boolean] :follow_redirects
        #   Overrides whether HTTP redirects will automatically be followed.
        #
        # @option kwargs [Integer] :max_redirects
        #   Overrides the maximum number of redirects to follow.
        #
        # @!macro request_kwargs
        #
        # @return [Hash{String => Object}, Array]
        #   The parsed JSON.
        #
        # @raise [ContentTypeError]
        #   Did not receive a response with a `Content-Type` of
        #   `application/json`.
        #
        # @raise [TooManyRedirects]
        #   Maximum number of redirects reached.
        #
        # @note This method will follow redirects by default.
        #
        # @example
        #   json = agent.get_json('https://example.com/data.json')
        #   # => {...}
        #
        def get_json(url,**kwargs)
          response = get(url,**kwargs)

          unless response.content_type.include?('application/json')
            raise(ContentTypeError,"response 'Content-Type' was not 'application/json': #{response.content_type.inspect}")
          end

          return ::JSON.parse(response.body)
        end

        #
        # Performs an HTTP POST to the URL.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP GET request for.
        #
        # @param [Boolean] follow_redirects
        #   Overrides whether HTTP redirects will automatically be followed.
        #
        # @param [Integer] max_redirects
        #   Overrides the maximum number of redirects to follow.
        #
        # @!macro request_kwargs
        #
        # @yield [response]
        #   If a block is given it will be passed the received HTTP response.
        #
        # @yieldparam [Net::HTTPResponse] response
        #   The received HTTP response object.
        #
        # @return [Net::HTTPResponse]
        #   The HTTP response object.
        #
        # @raise [TooManyRedirects]
        #   Maximum number of redirects reached.
        #
        # @note
        #   If the response is an HTTP redirect, then {#get} will be called to
        #   follow any redirects.
        #
        # @example
        #   response = agent.post('https://example.com/form', form_data: {'foo' => 'bar'})
        #   # => #<Net::HTTPResponse:...>
        #
        def post(url, follow_redirects: @follow_redirects,
                      max_redirects:    @max_redirects,
                      **kwargs)
          response = http_post(url,**kwargs)

          if follow_redirects && response.kind_of?(Net::HTTPRedirection)
            location = response['Location']

            response = begin
                         get(location, follow_redirects: follow_redirects,
                                       max_redirects:    max_redirects - 1)
                       rescue TooManyRedirects
                         raise(TooManyRedirects,"maximum number of redirects reached: #{url.inspect}")
                       end
          end

          yield response if block_given?
          return response
        end

        #
        # Performs an HTTP POST to the URL and parses the HTML response.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP POST request for.
        #
        # @option kwargs [Boolean] :follow_redirects
        #   Overrides whether HTTP redirects will automatically be followed.
        #
        # @option kwargs [Integer] :max_redirects
        #   Overrides the maximum number of redirects to follow.
        #
        # @!macro request_kwargs
        #
        # @return [Nokogiri::HTML::Document]
        #   The parsed HTML response.
        #
        # @raise [TooManyRedirects]
        #   Maximum number of redirects reached.
        #
        # @raise [ContentTypeError]
        #   Did not receive a response with a `Content-Type` of
        #   `text/html`.
        #
        # @note
        #   If the response is an HTTP redirect, then {#get} will be called to
        #   follow any redirects.
        #
        # @example Send a POST request and parses the HTML response:
        #   doc = agent.post_html 'https://example.com/form', form_data: {foo: 'bar'})
        #   # => #<Nokogiri::HTML::Document:...>
        #
        def post_html(url,**kwargs)
          response = post(url,**kwargs)

          unless response.content_type.include?('text/html')
            raise(ContentTypeError,"response 'Content-Type' was not 'text/html': #{response.content_type.inspect}")
          end

          return Nokogiri::HTML(response.body)
        end

        #
        # Performs an HTTP POST to the URL and parses the XML response.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP POST request for.
        #
        # @option kwargs [Boolean] :follow_redirects
        #   Overrides whether HTTP redirects will automatically be followed.
        #
        # @option kwargs [Integer] :max_redirects
        #   Overrides the maximum number of redirects to follow.
        #
        # @!macro request_kwargs
        #
        # @return [Nokogiri::XML::Document]
        #   The parsed XML response.
        #
        # @raise [TooManyRedirects]
        #   Maximum number of redirects reached.
        #
        # @raise [ContentTypeError]
        #   Did not receive a response with a `Content-Type` of
        #   `text/xml`.
        #
        # @note
        #   If the response is an HTTP redirect, then {#get} will be called to
        #   follow any redirects.
        #
        # @example Send a POST request to the form and parses the XML response:
        #   doc = agent.post_xml 'https://example.com/form', form_data: {foo: 'bar'}
        #   # => #<Nokogiri::XML::Document:...>
        #
        def post_xml(url,**kwargs)
          response = post(url,**kwargs)

          unless response.content_type.include?('text/xml')
            raise(ContentTypeError,"response 'Content-Type' was not 'application/json': #{response.content_type.inspect}")
          end

          return Nokogiri::XML(response.body)
        end

        #
        # Performs an HTTP POST to the URL and parses the JSON response.
        #
        # @param [URI::HTTP, Addressable::URI, String] url
        #   The URL to create the HTTP POST request for.
        #
        # @option kwargs [Boolean] :follow_redirects
        #   Overrides whether HTTP redirects will automatically be followed.
        #
        # @option kwargs [Integer] :max_redirects
        #   Overrides the maximum number of redirects to follow.
        #
        # @!macro request_kwargs
        #
        # @return [Hash{String => Object}, Array]
        #   The parses JSON response.
        #
        # @raise [TooManyRedirects]
        #   Maximum number of redirects reached.
        #
        # @raise [ContentTypeError]
        #   Did not receive a response with a `Content-Type` of
        #   `application/json`.
        #
        # @note
        #   If the response is an HTTP redirect, then {#get} will be called to
        #   follow any redirects.
        #
        # @example Send a POST request to the form and parse the JSON response:
        #   json = agent.post_json 'https://example.com/form', form_data: {foo: 'bar'}
        #   # => {...}
        #
        # @example Send a POST request containing JSON and parse the JSON response:
        #   json = agent.post_json 'https://example.com/api/end-point', json: {foo: 'bar'}
        #   # => {...}
        #
        def post_json(url,**kwargs)
          response = post(url,**kwargs)

          unless response.content_type.include?('application/json')
            raise(ContentTypeError,"response 'Content-Type' was not 'application/json': #{response.content_type.inspect}")
          end

          return ::JSON.parse(response.body)
        end

        private

        #
        # Normalizes a URL.
        #
        # @param [URI::HTTP, Addressable::URI, String, Object] url
        #   The URL or URI to normalize.
        #
        # @return [URI::HTTP, Addressable::URI]
        #   The parsed URL.
        #
        def normalize_url(url)
          case url
          when URI::HTTP, Addressable::URI then url
          when String                      then Addressable::URI.parse(url)
          else
            raise(ArgumentError,"url must be a URI::HTTP, Addressable::URI, or a String: #{url.inspect}")
          end
        end

        #
        # Fetches an existing HTTP session or creates a new one for the given
        # URI.
        #
        # @param [URI::HTTP] uri
        #   The URL to retrieve or create an HTTP session for.
        #
        # @return [Ronin::Support::Network::HTTP]
        #   The HTTP session.
        #
        def session_for(uri)
          key = [uri.scheme, uri.host, uri.port]

          @sessions[key] ||= Support::Network::HTTP.connect_uri(
            uri, proxy:      @proxy,
                 ssl:        (@ssl if uri.scheme == 'https'),
                 user_agent: @user_agent
          )
        end

      end
    end
  end
end
