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

require 'ronin/support/web/agent'

module Ronin
  module Support
    module Web
      class Agent
        #
        # Provides helper methods for performing high-level web requests.
        #
        # ## Features
        #
        # * Automatically follows redirects.
        # * Provides high-level methods for requesting and parsing HTML, XML, or
        #   JSON.
        # * Maintains a persistent connection pool.
        #
        # ## Anti-Features
        #
        # * Does not cache files or write to the disk.
        # * Does not evaluate JavaScript.
        #
        module Mixin
          #
          # The web agent object.
          #
          # @return [Agent]
          #
          def web_agent
            @web_agent ||= Agent.new
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
          # Gets a URL and returns the response.
          #
          # @param [URI::HTTP, Addressable::URI, String] url
          #   The URL to create the HTTP GET request for.
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
          #   response = web_get('https://example.com/')
          #   # => #<Net::HTTPResponse:...>
          #
          def web_get(url,**kwargs,&block)
            web_agent.get(url,**kwargs,&block)
          end

          alias get web_get

          #
          # Gets the URL and returns the parsed HTML.
          #
          # @param [URI::HTTP, Addressable::URI, String] url
          #   The URL to create the HTTP GET request for.
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
          #   doc = web_get_html('https://example.com/page.html')
          #   # => #<Nokogiri::HTML::Document:...>
          #
          def web_get_html(url,**kwargs)
            web_agent.get_html(url,**kwargs)
          end

          alias get_html web_get_html

          #
          # Gets the URL and returns the parsed XML.
          #
          # @param [URI::HTTP, Addressable::URI, String] url
          #   The URL to create the HTTP GET request for.
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
          #   doc = web_get_xml('https://example.com/data.xml')
          #   # => #<Nokogiri::XML::Document:...>
          #
          def web_get_xml(url,**kwargs)
            web_agent.get_xml(url,**kwargs)
          end

          alias get_xml web_get_xml

          #
          # Gets the URL and returns the parsed JSON.
          #
          # @param [URI::HTTP, Addressable::URI, String] url
          #   The URL to create the HTTP GET request for.
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
          #   json = web_get_json('https://example.com/data.json')
          #   # => {...}
          #
          def web_get_json(url,**kwargs)
            web_agent.get_json(url,**kwargs)
          end

          alias get_json web_get_json

          #
          # Performs an HTTP POST to the URL.
          #
          # @param [URI::HTTP, Addressable::URI, String] url
          #   The URL to create the HTTP GET request for.
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
          #   response = web_post('https://example.com/form', form_data: {'foo' => 'bar'})
          #   # => #<Net::HTTPResponse:...>
          #
          def web_post(url,**kwargs,&block)
            web_agent.post(url,**kwargs,&block)
          end

          alias post web_post

          #
          # Performs an HTTP POST to the URL and parses the HTML response.
          #
          # @param [URI::HTTP, Addressable::URI, String] url
          #   The URL to create the HTTP POST request for.
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
          #   doc = web_post_html 'https://example.com/form', form_data: {foo: 'bar'})
          #   # => #<Nokogiri::HTML::Document:...>
          #
          def web_post_html(url,**kwargs)
            web_agent.post_html(url,**kwargs)
          end

          alias post_html web_post_html

          #
          # Performs an HTTP POST to the URL and parses the XML response.
          #
          # @param [URI::HTTP, Addressable::URI, String] url
          #   The URL to create the HTTP POST request for.
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
          #   doc = web_post_xml 'https://example.com/form', form_data: {foo: 'bar'}
          #   # => #<Nokogiri::XML::Document:...>
          #
          def web_post_xml(url,**kwargs)
            web_agent.post_xml(url,**kwargs)
          end

          alias post_xml web_post_xml

          #
          # Performs an HTTP POST to the URL and parses the JSON response.
          #
          # @param [URI::HTTP, Addressable::URI, String] url
          #   The URL to create the HTTP POST request for.
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
          #   json = web_post_json 'https://example.com/form', form_data: {foo: 'bar'}
          #   # => {...}
          #
          # @example Send a POST request containing JSON and parse the JSON response:
          #   json = web_post_json 'https://example.com/api/end-point', json: {foo: 'bar'}
          #   # => {...}
          #
          def web_post_json(url,**kwargs)
            web_agent.post_json(url,**kwargs)
          end

          alias post_json web_post_json
        end
      end
    end
  end
end
