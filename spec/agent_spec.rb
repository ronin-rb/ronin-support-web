require 'spec_helper'
require 'ronin/support/web/agent'

require 'webmock/rspec'

describe Ronin::Support::Web::Agent do
  describe "#initialize" do
    it "must default #follow_redirects? to true" do
      expect(subject.follow_redirects?).to be(true)
    end

    context "when initialized with the `follow_redirects: false`" do
      subject { described_class.new(follow_redirects: false) }

      it "must #follow_redirects? to false" do
        expect(subject.follow_redirects?).to be(false)
      end
    end

    it "must default #max_redirects to 20" do
      expect(subject.max_redirects).to eq(20)
    end

    context "when initialized with the max_redirects: keyword argument" do
      let(:max_redirects) { 10 }

      subject { described_class.new(max_redirects: max_redirects) }

      it "must set #max_redirects" do
        expect(subject.max_redirects).to eq(max_redirects)
      end
    end

    it "must default #proxy to nil" do
      expect(subject.proxy).to be(nil)
    end

    let(:host)  { '127.0.0.1' }
    let(:port)  { 8080 }
    let(:proxy) { URI::HTTP.build(host: host, port: port) }

    context "when Ronin::Support::Network::HTTP.proxy is set" do
      before { Ronin::Support::Network::HTTP.proxy = proxy }

      it "must default #proxy to Ronin::Support::Network::HTTP.proxy" do
        expect(subject.proxy).to be(proxy)
      end

      after { Ronin::Support::Network::HTTP.proxy = nil }
    end

    context "when initialized with the proxy: keyword argument" do
      subject { described_class.new(proxy: proxy) }

      it "should set #proxy_addr and #proxy_port to the custom proxy" do
        expect(subject.proxy).to be(proxy)
      end
    end

    it "must default #user_agent to nil" do
      expect(subject.user_agent).to be(nil)
    end

    context "when Ronin::Support::Network::HTTP.user_agent is set" do
      let(:user_agent) { 'test' }

      before { Ronin::Support::Network::HTTP.user_agent = user_agent }

      it "must default #user_agent to Ronin::Support::Network::HTTP.user_agent" do
        expect(subject.user_agent).to eq(user_agent)
      end

      after { Ronin::Support::Network::HTTP.user_agent = nil }
    end

    context "when initialized with the user_agent: keyword argument" do
      context "and it's a String" do
        let(:user_agent) { 'test2' }

        subject { described_class.new(user_agent: user_agent) }

        it "must set #user_agent to the String" do
          expect(subject.user_agent).to eq(user_agent)
        end
      end

      context "and it's a Symbol" do
        let(:user_agent) { :chrome_linux }

        subject { described_class.new(user_agent: user_agent) }

        it "must set #user_agent to the Symbol" do
          expect(subject.user_agent).to eq(user_agent)
        end
      end
    end
  end

  let(:host) { 'example.com' }
  let(:path) { '/path' }
  let(:uri)  { URI::HTTP.build(host: host, path: path) }

  describe "#http_request" do
    let(:method) { :get }

    it "must send a request with the given method and URI's path to the URI's host and return an Net::HTTPResponse object" do
      stub_request(method,uri)

      expect(subject.http_request(method,uri)).to be_kind_of(Net::HTTPResponse)

      expect(WebMock).to have_requested(method,uri)
    end

    context "when the headers: keyword argument is given" do
      let(:additional_headers) do
        {
          'X-Foo' => 'bar'
        }
      end

      it "must add the additional headers to the request" do
        stub_request(method,uri).with(headers: additional_headers)

        expect(subject.http_request(method,uri, headers: additional_headers)).to be_kind_of(Net::HTTPResponse)

        expect(WebMock).to have_requested(method,uri).with(headers: additional_headers)
      end
    end

    context "when the cookie: keyword argument is given" do
      let(:custom_cookie) do
        Ronin::Support::Network::HTTP::Cookie.new('foo' => 'bar')
      end

      it "must add the Cookie header to the request" do
        stub_request(method,uri).with(headers: {'Cookie' => custom_cookie.to_s})

        expect(subject.http_request(method,uri, cookie: custom_cookie)).to be_kind_of(Net::HTTPResponse)

        expect(WebMock).to have_requested(method,uri).with(headers: {'Cookie' => custom_cookie.to_s})
      end
    end

    context "when the URI contains an authentication user name" do
      let(:user) { 'joe' }
      let(:uri_with_auth) do
        URI::HTTP.build(
          userinfo: user,
          host:     host,
          path:     path
        )
      end

      let(:headers) do
        {
          'Authorization' => "Basic am9lOg=="
        }
      end

      it "must set the Authorization header with the URI's user name" do
        stub_request(method,uri).with(headers: headers)

        expect(subject.http_request(method,uri_with_auth)).to be_kind_of(Net::HTTPResponse)

        expect(WebMock).to have_requested(method,uri).with(headers: headers)
      end

      context "and when the URI contains a password" do
        let(:password) { 'secret' }
        let(:uri_with_auth) do
          URI::HTTP.build(
            userinfo: "#{user}:#{password}",
            host:     host,
            path:     path
          )
        end

        let(:headers) do
          {
            'Authorization' => "Basic am9lOnNlY3JldA=="
          }
        end

        it "must set the Authorization header with the URI's user and password" do
          stub_request(method,uri).with(headers: headers)

          expect(subject.http_request(method,uri_with_auth)).to be_kind_of(Net::HTTPResponse)

          expect(WebMock).to have_requested(method,uri).with(headers: headers)
        end
      end
    end
  end

  describe "#http_response_status" do
    let(:status) { 200 }

    it "must send a HTTP HEAD request and return the response status code as an Integer" do
      stub_request(:head,uri).to_return(status: status)

      expect(subject.http_response_status(uri)).to eq(status)
    end

    context "when also given a method argument" do
      let(:method) { :get }

      it "must send the HTTP request method and return the response status code as an Integer" do
        stub_request(method,uri).to_return(status: status)

        expect(subject.http_response_status(method,uri)).to eq(status)
      end
    end
  end

  describe "#http_ok?" do
    context "when the HTTP response status is 200" do
      it "must send a HTTP HEAD request and return true" do
        stub_request(:head,uri).to_return(status: 200)

        expect(subject.http_ok?(uri)).to be(true)
      end

      context "when also given a method argument" do
        let(:method) { :get }

        it "must send the given HTTP request method and return true" do
          stub_request(method,uri).to_return(status: 200)

          expect(subject.http_ok?(method,uri)).to be(true)
        end
      end
    end

    context "when the HTTP response status is not 200" do
      it "must send a HTTP HEAD request and return false" do
        stub_request(:head,uri).to_return(status: 404)

        expect(subject.http_ok?(uri)).to be(false)
      end

      context "when also given a method argument" do
        let(:method) { :get }

        it "must send the given HTTP request method and return false" do
          stub_request(method,uri).to_return(status: 404)

          expect(subject.http_ok?(method,uri)).to be(false)
        end
      end
    end
  end

  describe "#http_response_headers" do
    let(:headers) do
      {'X-Test' => 'foo' }
    end

    it "send send a HTTP HEAD request and return the capitalized response headers" do
      stub_request(:head,uri).to_return(headers: headers)

      expect(subject.http_response_headers(uri)).to eq(headers)
    end

    context "when also given a method argument" do
      let(:method) { :get }

      it "send send the HTTP request method and return the capitalized response headers" do
        stub_request(method,uri).to_return(headers: headers)

        expect(subject.http_response_headers(method,uri)).to eq(headers)
      end
    end
  end

  describe "#http_server_header" do
    let(:server_header) { 'Apache' }

    it "must send a HTTP HEAD request for the given URI and return the 'Server' header" do
      stub_request(:head,uri).to_return(
        headers: {'Server' => server_header}
      )

      expect(subject.http_server_header(uri)).to eq(server_header)
    end

    context "when also given a method: keyword argument" do
      let(:method) { :get }

      it "must send the HTTP request method for the given URI and return the 'Server' header" do
        stub_request(method,uri).to_return(
          headers: {'Server' => server_header}
        )

        expect(subject.http_server_header(uri, method: method)).to eq(server_header)
      end
    end
  end

  describe "#http_powered_by_header" do
    let(:x_powered_by_header) { 'PHP/1.2.3' }

    it "must send a HTTP HEAD request for the given URI and return the 'X-Powered-By' header" do
      stub_request(:head,uri).to_return(
        headers: {'X-Powered-By' => x_powered_by_header}
      )

      expect(subject.http_powered_by_header(uri)).to eq(x_powered_by_header)
    end

    context "when also given a method: keyword argument" do
      let(:method) { :get }

      it "must send the HTTP request method for the given URI and return the 'X-Server-By' header" do
        stub_request(method,uri).to_return(
          headers: {'X-Powered-By' => x_powered_by_header}
        )

        expect(subject.http_powered_by_header(uri, method: method)).to eq(x_powered_by_header)
      end
    end
  end

  describe "#http_response_body" do
    let(:body) { 'Test body' }

    it "must send a HTTP GET request and return the response body" do
      stub_request(:get,uri).to_return(body: body)

      expect(subject.http_response_body(uri)).to eq(body)
    end

    context "when also given a method argument" do
      let(:method) { :post }

      it "must send the HTTP request method and return the response body" do
        stub_request(method,uri).to_return(body: body)

        expect(subject.http_response_body(method,uri)).to be(body)
      end
    end
  end

  [:copy, :delete, :get, :head, :lock, :mkcol, :move, :options, :patch, :post, :propfind, :proppatch, :put, :trace, :unlock].each do |method|
    describe "#http_#{method}" do
      let(:method) { method }

      it "must send a HTTP #{method.upcase} request and return a Net::HTTP response object" do
        stub_request(method,uri)

        expect(subject.send(:"http_#{method}",uri)).to be_kind_of(Net::HTTPResponse)
      end
    end
  end

  describe "#http_allowed_methods" do
    let(:allow)   { "OPTIONS, GET, HEAD, POST"     }
    let(:methods) { [:options, :get, :head, :post] }

    it "must send an OPTIONS request for the given URI and return the parsed Allow header" do
      stub_request(:options,uri).to_return(headers: {'Allow' => allow})

      expect(subject.http_allowed_methods(uri)).to eq(methods)
    end
  end

  describe "#http_get_headers" do
    let(:headers) do
      {'X-Test' => 'foo'}
    end

    it "must send a HTTP GET request for the given URI and return the response headers" do
      stub_request(:get,uri).to_return(headers: headers)

      expect(subject.http_get_headers(uri)).to eq(headers)
    end
  end

  describe "#http_get_cookies" do
    it "must send a HTTP GET request for the path" do
      stub_request(:get,uri)

      subject.http_get_cookies(uri)
    end

    context "when the response contains a Set-Cookie header" do
      let(:name)  { 'foo' }
      let(:value) { 'bar' }

      let(:headers) do
        {'Set-Cookie' => "#{name}=#{value}"}
      end

      it "must return an Array containing the parsed Set-Cookie header" do
        stub_request(:get,uri).to_return(headers: headers)

        cookies = subject.http_get_cookies(uri)

        expect(cookies).to be_kind_of(Array)
        expect(cookies.length).to eq(1)
        expect(cookies[0]).to be_kind_of(Ronin::Support::Network::HTTP::SetCookie)
        expect(cookies[0][name]).to eq(value)
      end
    end

    context "when the response contains multiple Set-Cookie headers" do
      let(:name1)  { 'foo' }
      let(:value1) { 'bar' }
      let(:name2)  { 'baz' }
      let(:value2) { 'qux' }

      let(:headers) do
        {'Set-Cookie' => ["#{name1}=#{value1}", "#{name2}=#{value2}"]}
      end

      it "must return an Array containing the parsed Set-Cookie headers" do
        stub_request(:get,uri).to_return(headers: headers)

        cookies = subject.http_get_cookies(uri)

        expect(cookies).to be_kind_of(Array)
        expect(cookies.length).to eq(2)
        expect(cookies[0]).to be_kind_of(Ronin::Support::Network::HTTP::SetCookie)
        expect(cookies[0][name2]).to eq(value2)
        expect(cookies[1]).to be_kind_of(Ronin::Support::Network::HTTP::SetCookie)
        expect(cookies[1][name1]).to eq(value1)
      end
    end

    context "when the response contains no Set-Cookie headers" do
      let(:headers) { {} }

      it "must return an empty Array" do
        stub_request(:get,uri).to_return(headers: headers)

        expect(subject.http_get_cookies(uri)).to eq([])
      end
    end
  end

  describe "#http_get_body" do
    let(:body) { 'Test body' }

    it "must send a HTTP GET request for the given URI and return the response body" do
      stub_request(:get,uri).to_return(body: body)

      subject.http_get_body(uri)
    end
  end

  describe "#http_post_headers" do
    let(:headers) do
      {'X-Test' => 'foo'}
    end

    it "must send a HTTP POST request for the given URI and return the response headers" do
      stub_request(:post,uri).to_return(headers: headers)

      expect(subject.http_post_headers(uri)).to eq(headers)
    end
  end

  describe "#http_post_body" do
    let(:body) { 'Test body' }

    it "must send a HTTP POST request for the given URI and return the response body" do
      stub_request(:post,uri).to_return(body: body)

      expect(subject.http_post_body(uri)).to eq(body)
    end
  end

  describe "#get" do
    it "must send a HTTP GET request for the given URI and return an Net::HTTPResponse object" do
      stub_request(:get,uri)

      expect(subject.get(uri)).to be_kind_of(Net::HTTPResponse)

      expect(WebMock).to have_requested(:get,uri)
    end

    context "and when the response is an HTTP redirect" do
      let(:redirect_url) { 'https://example.com/path2' }

      it "must follow the 'Location' URL in the redirect and return that response" do
        stub_request(:get,uri).to_return(
          status: 301,
          headers: {
            'Location' => redirect_url
          }
        )
        stub_request(:get,redirect_url).to_return(body: 'final response')

        response = subject.get(uri)
        expect(response).to be_kind_of(Net::HTTPResponse)
        expect(response.body).to eq('final response')

        expect(WebMock).to have_requested(:get,uri)
        expect(WebMock).to have_requested(:get,redirect_url)
      end

      context "but requesting the HTTP redirect URL returns yet to another HTTP redirect" do
        let(:redirect_url1) { 'https://example.com/path2' }
        let(:redirect_url2) { 'https://example.com/path3' }

        it "must follow the next 'Location' URL of each redirect until a non-HTTP redirect respnse is returned" do
          stub_request(:get,uri).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url1
            }
          )
          stub_request(:get,redirect_url1).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url2
            }
          )
          stub_request(:get,redirect_url2).to_return(body: 'final response')

          response = subject.get(uri)
          expect(response).to be_kind_of(Net::HTTPResponse)
          expect(response.body).to eq('final response')

          expect(WebMock).to have_requested(:get,uri)
          expect(WebMock).to have_requested(:get,redirect_url1)
          expect(WebMock).to have_requested(:get,redirect_url2)
        end
      end

      context "but the number of HTTP redirects equals the max_redirects: keyword argument" do
        let(:redirect_url1) { 'https://example.com/path2' }
        let(:redirect_url2) { 'https://example.com/path3' }

        it "must return the first non-HTTP redirect response" do
          stub_request(:get,uri).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url1
            }
          )
          stub_request(:get,redirect_url1).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url2
            }
          )
          stub_request(:get,redirect_url2).to_return(body: 'final response')

          response = subject.get(uri, max_redirects: 2)
          expect(response).to be_kind_of(Net::HTTPResponse)
          expect(response.body).to eq('final response')

          expect(WebMock).to have_requested(:get,uri)
          expect(WebMock).to have_requested(:get,redirect_url1)
          expect(WebMock).to have_requested(:get,redirect_url2)
        end
      end

      context "but the number of HTTP redirects equals #max_redirects" do
        let(:max_redirects) { 2 }

        subject { described_class.new(max_redirects: max_redirects) }

        let(:redirect_url1) { 'https://example.com/path2' }
        let(:redirect_url2) { 'https://example.com/path3' }

        it "must return the first non-HTTP redirect response" do
          stub_request(:get,uri).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url1
            }
          )
          stub_request(:get,redirect_url1).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url2
            }
          )
          stub_request(:get,redirect_url2).to_return(body: 'final response')

          response = subject.get(uri, max_redirects: 2)
          expect(response).to be_kind_of(Net::HTTPResponse)
          expect(response.body).to eq('final response')

          expect(WebMock).to have_requested(:get,uri)
          expect(WebMock).to have_requested(:get,redirect_url1)
          expect(WebMock).to have_requested(:get,redirect_url2)
        end
      end

      context "but the number of HTTP redirects exceeds the max_redirects: keyword argument" do
        let(:redirect_url1) { 'https://example.com/path2' }
        let(:redirect_url2) { 'https://example.com/path3' }

        it "must raise a TooMnayRedirects exception" do
          stub_request(:get,uri).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url1
            }
          )
          stub_request(:get,redirect_url1).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url2
            }
          )

          expect {
            subject.get(uri, max_redirects: 1)
          }.to raise_error(described_class::TooManyRedirects,"maximum number of redirects reached: #{uri.inspect}")

          expect(WebMock).to have_requested(:get,uri)
          expect(WebMock).to have_requested(:get,redirect_url1)
        end
      end

      context "but the number of HTTP redirects exceeds #max_redirects" do
        let(:max_redirects) { 1 }

        subject { described_class.new(max_redirects: max_redirects) }

        let(:redirect_url1) { 'https://example.com/path2' }
        let(:redirect_url2) { 'https://example.com/path3' }

        it "must raise a TooMnayRedirects exception" do
          stub_request(:get,uri).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url1
            }
          )
          stub_request(:get,redirect_url1).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url2
            }
          )

          expect {
            subject.get(uri)
          }.to raise_error(described_class::TooManyRedirects,"maximum number of redirects reached: #{uri.inspect}")

          expect(WebMock).to have_requested(:get,uri)
          expect(WebMock).to have_requested(:get,redirect_url1)
        end
      end

      context "but when the follow_redirects: keyword argument is false" do
        it "must return the HTTP response for the URI" do
          stub_request(:get,uri).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url
            }
          )

          response = subject.get(uri, follow_redirects: false)
          expect(response).to be_kind_of(Net::HTTPRedirection)
          expect(response['Location']).to eq(redirect_url)
        end
      end

      context "but #follow_redirects? is false" do
        subject { described_class.new(follow_redirects: false) }

        it "must return the HTTP response for the URI" do
          stub_request(:get,uri).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url
            }
          )

          response = subject.get(uri)
          expect(response).to be_kind_of(Net::HTTPRedirection)
          expect(response['Location']).to eq(redirect_url)
        end
      end
    end
  end

  describe "#get_html" do
    let(:html) do
      <<~HTML
        <html>
          <body>
            <p>hello world</p>
          </body>
        </html>
      HTML
    end

    it "must send a HTTP GET request for the given URI" do
      stub_request(:get,uri).to_return(
        headers: {
          'Content-Type' => 'text/html'
        },
        body: html
      )

      subject.get_html(uri)

      expect(WebMock).to have_requested(:get,uri)
    end

    context "when the response Content-Type contains 'text/html'" do
      it "must return the parsed HTML" do
        stub_request(:get,uri).to_return(
          headers: {
            'Content-Type' => 'text/html'
          },
          body: html
        )

        doc = subject.get_html(uri)

        expect(doc).to be_kind_of(Nokogiri::HTML::Document)

        # XXX: nokogiri's java extensions behave differently from libxml2
        if RUBY_ENGINE == 'jruby'
          expect(doc.to_s).to eq(
            <<~HTML.chomp
              <html><head></head><body>
                  <p>hello world</p>
                
              </body></html>
            HTML
          )
        else
          expect(doc.to_s).to eq(
            <<~HTML
              <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
              #{html.chomp}
            HTML
          )
        end
      end
    end

    context "when the response Content-Type does not contain 'text/html'" do
      it "must raise an ContentTypeError exception" do
        stub_request(:get,uri).to_return(
          headers: {'Content-Type' => 'text/plain'},
          body:    %{hello world}
        )

        expect {
          subject.get_html(uri)
        }.to raise_error(described_class::ContentTypeError,"response 'Content-Type' was not 'text/html': \"text/plain\"")
      end
    end
  end

  describe "#get_xml" do
    let(:xml) do
      <<~XML
        <?xml version="1.0"?>
        <foo>
          bar
        </foo>
      XML
    end

    it "must send a HTTP GET request for the given URI" do
      stub_request(:get,uri).to_return(
        headers: {'Content-Type' => 'text/xml'},
        body:    xml
      )

      subject.get_xml(uri)

      expect(WebMock).to have_requested(:get,uri)
    end

    context "when the response Content-Type contains 'text/xml'" do
      it "must return the parsed XML" do
        stub_request(:get,uri).to_return(
          headers: {'Content-Type' => 'text/xml'},
          body:    xml
        )

        doc = subject.get_xml(uri)

        expect(doc).to be_kind_of(Nokogiri::XML::Document)

        # XXX: nokogiri's java extensions behave differently from libxml2
        if RUBY_ENGINE == 'jruby'
          expect(doc.to_s).to eq(xml.chomp)
        else
          expect(doc.to_s).to eq(xml)
        end
      end
    end

    context "when the response Content-Type does not contain 'text/xml'" do
      it "must raise an ContentTypeError exception" do
        stub_request(:get,uri).to_return(
          headers: {'Content-Type' => 'text/plain'},
          body:    %{hello world}
        )

        expect {
          subject.get_xml(uri)
        }.to raise_error(described_class::ContentTypeError,"response 'Content-Type' was not 'text/xml': \"text/plain\"")
      end
    end
  end

  describe "#get_json" do
    let(:data) do
      {'foo' => 'bar'}
    end
    let(:json) { data.to_json }

    it "must send a HTTP GET request for the given URI" do
      stub_request(:get,uri).to_return(
        headers: {'Content-Type' => 'application/json'},
        body:    json
      )

      subject.get_json(uri)

      expect(WebMock).to have_requested(:get,uri)
    end

    context "when the response Content-Type contains 'application/json'" do
      it "must return the parsed JSON" do
        stub_request(:get,uri).to_return(
          headers: {'Content-Type' => 'application/json'},
          body:    json
        )

        expect(subject.get_json(uri)).to eq(data)
      end
    end

    context "when the response Content-Type does not contain 'application/json'" do
      it "must raise an ContentTypeError exception" do
        stub_request(:get,uri).to_return(
          headers: {'Content-Type' => 'text/plain'},
          body:    %{hello world}
        )

        expect {
          subject.get_json(uri)
        }.to raise_error(described_class::ContentTypeError,"response 'Content-Type' was not 'application/json': \"text/plain\"")
      end
    end
  end

  describe "#post" do
    it "must send a HTTP POST request for the given URI and return an Net::HTTPResponse object" do
      stub_request(:post,uri)

      expect(subject.post(uri)).to be_kind_of(Net::HTTPResponse)

      expect(WebMock).to have_requested(:post,uri)
    end

    context "and when the response is an HTTP redirect" do
      let(:redirect_url) { 'https://example.com/path2' }

      it "must send a HTTP GET request for the 'Location' URL in the redirect and return that response" do
        stub_request(:post,uri).to_return(
          status: 301,
          headers: {
            'Location' => redirect_url
          }
        )
        stub_request(:get,redirect_url).to_return(body: 'final response')

        response = subject.post(uri)
        expect(response).to be_kind_of(Net::HTTPResponse)
        expect(response.body).to eq('final response')

        expect(WebMock).to have_requested(:post,uri)
        expect(WebMock).to have_requested(:get,redirect_url)
      end

      context "but requesting the HTTP redirect URL returns yet to another HTTP redirect" do
        let(:redirect_url1) { 'https://example.com/path2' }
        let(:redirect_url2) { 'https://example.com/path3' }

        it "must follow the next 'Location' URL of each redirect until a non-HTTP redirect respnse is returned" do
          stub_request(:post,uri).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url1
            }
          )
          stub_request(:get,redirect_url1).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url2
            }
          )
          stub_request(:get,redirect_url2).to_return(body: 'final response')

          response = subject.post(uri)
          expect(response).to be_kind_of(Net::HTTPResponse)
          expect(response.body).to eq('final response')

          expect(WebMock).to have_requested(:post,uri)
          expect(WebMock).to have_requested(:get,redirect_url1)
          expect(WebMock).to have_requested(:get,redirect_url2)
        end
      end

      context "but the number of HTTP redirects equals the max_redirects: keyword argument" do
        let(:redirect_url1) { 'https://example.com/path2' }
        let(:redirect_url2) { 'https://example.com/path3' }

        it "must return the first non-HTTP redirect response" do
          stub_request(:post,uri).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url1
            }
          )
          stub_request(:get,redirect_url1).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url2
            }
          )
          stub_request(:get,redirect_url2).to_return(body: 'final response')

          response = subject.post(uri, max_redirects: 2)
          expect(response).to be_kind_of(Net::HTTPResponse)
          expect(response.body).to eq('final response')

          expect(WebMock).to have_requested(:post,uri)
          expect(WebMock).to have_requested(:get,redirect_url1)
          expect(WebMock).to have_requested(:get,redirect_url2)
        end
      end

      context "but the number of HTTP redirects equals #max_redirects" do
        let(:max_redirects) { 2 }

        subject { described_class.new(max_redirects: max_redirects) }

        let(:redirect_url1) { 'https://example.com/path2' }
        let(:redirect_url2) { 'https://example.com/path3' }

        it "must return the first non-HTTP redirect response" do
          stub_request(:post,uri).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url1
            }
          )
          stub_request(:get,redirect_url1).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url2
            }
          )
          stub_request(:get,redirect_url2).to_return(body: 'final response')

          response = subject.post(uri, max_redirects: 2)
          expect(response).to be_kind_of(Net::HTTPResponse)
          expect(response.body).to eq('final response')

          expect(WebMock).to have_requested(:post,uri)
          expect(WebMock).to have_requested(:get,redirect_url1)
          expect(WebMock).to have_requested(:get,redirect_url2)
        end
      end

      context "but the number of HTTP redirects exceeds the max_redirects: keyword argument" do
        let(:redirect_url1) { 'https://example.com/path2' }
        let(:redirect_url2) { 'https://example.com/path3' }

        it "must raise a TooMnayRedirects exception" do
          stub_request(:post,uri).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url1
            }
          )
          stub_request(:get,redirect_url1).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url2
            }
          )

          expect {
            subject.post(uri, max_redirects: 1)
          }.to raise_error(described_class::TooManyRedirects,"maximum number of redirects reached: #{uri.inspect}")

          expect(WebMock).to have_requested(:post,uri)
          expect(WebMock).to have_requested(:get,redirect_url1)
        end
      end

      context "but the number of HTTP redirects exceeds #max_redirects" do
        let(:max_redirects) { 1 }

        subject { described_class.new(max_redirects: max_redirects) }

        let(:redirect_url1) { 'https://example.com/path2' }
        let(:redirect_url2) { 'https://example.com/path3' }

        it "must raise a TooMnayRedirects exception" do
          stub_request(:post,uri).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url1
            }
          )
          stub_request(:get,redirect_url1).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url2
            }
          )

          expect {
            subject.post(uri)
          }.to raise_error(described_class::TooManyRedirects,"maximum number of redirects reached: #{uri.inspect}")

          expect(WebMock).to have_requested(:post,uri)
          expect(WebMock).to have_requested(:get,redirect_url1)
        end
      end

      context "but when the follow_redirects: keyword argument is false" do
        it "must return the HTTP response for the URI" do
          stub_request(:post,uri).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url
            }
          )

          response = subject.post(uri, follow_redirects: false)
          expect(response).to be_kind_of(Net::HTTPRedirection)
          expect(response['Location']).to eq(redirect_url)
        end
      end

      context "but #follow_redirects? is false" do
        subject { described_class.new(follow_redirects: false) }

        it "must return the HTTP response for the URI" do
          stub_request(:post,uri).to_return(
            status: 301,
            headers: {
              'Location' => redirect_url
            }
          )

          response = subject.post(uri)
          expect(response).to be_kind_of(Net::HTTPRedirection)
          expect(response['Location']).to eq(redirect_url)
        end
      end
    end
  end

  describe "#post_html" do
    let(:html) do
      <<~HTML
        <html>
          <body>
            <p>hello world</p>
          </body>
        </html>
      HTML
    end

    it "must send a HTTP POST request for the given URI" do
      stub_request(:post,uri).to_return(
        headers: {'Content-Type' => 'text/html'},
        body:    html
      )

      subject.post_html(uri)

      expect(WebMock).to have_requested(:post,uri)
    end

    context "when the response Content-Type contains 'text/html'" do
      it "must return the parsed HTML" do
        stub_request(:post,uri).to_return(
          headers: {'Content-Type' => 'text/html'},
          body:    html
        )

        doc = subject.post_html(uri)

        expect(doc).to be_kind_of(Nokogiri::HTML::Document)

        # XXX: nokogiri's java extensions behave differently from libxml2
        if RUBY_ENGINE == 'jruby'
          expect(doc.to_s).to eq(
            <<~HTML.chomp
              <html><head></head><body>
                  <p>hello world</p>
                
              </body></html>
            HTML
          )
        else
          expect(doc.to_s).to eq(
            <<~HTML
              <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
              #{html.chomp}
            HTML
          )
        end
      end
    end

    context "when the response Content-Type does not contain 'text/html'" do
      it "must raise an ContentTypeError exception" do
        stub_request(:post,uri).to_return(
          headers: {'Content-Type' => 'text/plain'},
          body:    %{hello world}
        )

        expect {
          subject.post_html(uri)
        }.to raise_error(described_class::ContentTypeError,"response 'Content-Type' was not 'text/html': \"text/plain\"")
      end
    end
  end

  describe "#post_xml" do
    let(:xml) do
      <<~XML
        <?xml version="1.0"?>
        <foo>
          bar
        </foo>
      XML
    end

    it "must send a HTTP POST request for the given URI" do
      stub_request(:post,uri).to_return(
        headers: {'Content-Type' => 'text/xml'},
        body:    xml
      )

      subject.post_xml(uri)

      expect(WebMock).to have_requested(:post,uri)
    end

    context "when the response Content-Type contains 'text/xml'" do
      it "must return the parsed XML" do
        stub_request(:post,uri).to_return(
          headers: {'Content-Type' => 'text/xml'},
          body:    xml
        )

        doc = subject.post_xml(uri)

        expect(doc).to be_kind_of(Nokogiri::XML::Document)

        # XXX: nokogiri's java extensions behave differently from libxml2
        if RUBY_ENGINE == 'jruby'
          expect(doc.to_s).to eq(xml.chomp)
        else
          expect(doc.to_s).to eq(xml)
        end
      end
    end

    context "when the response Content-Type does not contain 'text/xml'" do
      it "must raise an ContentTypeError exception" do
        stub_request(:post,uri).to_return(
          headers: {'Content-Type' => 'text/plain'},
          body:    %{hello world}
        )

        expect {
          subject.post_xml(uri)
        }.to raise_error(described_class::ContentTypeError,"response 'Content-Type' was not 'application/json': \"text/plain\"")
      end
    end
  end

  describe "#post_json" do
    let(:data) do
      {'foo' => 'bar'}
    end
    let(:json) { data.to_json }

    it "must send a HTTP POST request for the given URI" do
      stub_request(:post,uri).to_return(
        headers: {'Content-Type' => 'application/json'},
        body:    json
      )

      subject.post_json(uri)

      expect(WebMock).to have_requested(:post,uri)
    end

    context "when the response Content-Type contains 'application/json'" do
      it "must return the parsed JSON" do
        stub_request(:post,uri).to_return(
          headers: {'Content-Type' => 'application/json'},
          body:    json
        )

        expect(subject.post_json(uri)).to eq(data)
      end
    end

    context "when the response Content-Type does not contain 'application/json'" do
      it "must raise an ContentTypeError exception" do
        stub_request(:post,uri).to_return(
          headers: {'Content-Type' => 'text/plain'},
          body:    %{hello world}
        )

        expect {
          subject.post_json(uri)
        }.to raise_error(described_class::ContentTypeError,"response 'Content-Type' was not 'application/json': \"text/plain\"")
      end
    end
  end
end
