require 'spec_helper'
require 'ronin/support/web/agent/mixin'

require 'webmock/rspec'

describe Ronin::Support::Web::Agent::Mixin do
  subject do
    obj = Object.new
    obj.extend described_class
    obj
  end

  let(:host) { 'example.com' }
  let(:path) { '/path' }
  let(:uri)  { URI::HTTP.build(host: host, path: path) }

  describe "#web_get" do
    it "must send a HTTP GET request for the given URI and return an Net::HTTPResponse object" do
      stub_request(:get,uri)

      expect(subject.web_get(uri)).to be_kind_of(Net::HTTPResponse)

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

        response = subject.web_get(uri)
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

          response = subject.web_get(uri)
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

          response = subject.web_get(uri, max_redirects: 2)
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
            subject.web_get(uri, max_redirects: 1)
          }.to raise_error(Ronin::Support::Web::Agent::TooManyRedirects,"maximum number of redirects reached: #{uri.inspect}")

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

          response = subject.web_get(uri, follow_redirects: false)
          expect(response).to be_kind_of(Net::HTTPRedirection)
          expect(response['Location']).to eq(redirect_url)
        end
      end
    end
  end

  describe "#web_get_html" do
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

      subject.web_get_html(uri)

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

        doc = subject.web_get_html(uri)

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
          subject.web_get_html(uri)
        }.to raise_error(Ronin::Support::Web::Agent::ContentTypeError,"response 'Content-Type' was not 'text/html': \"text/plain\"")
      end
    end
  end

  describe "#web_get_xml" do
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

      subject.web_get_xml(uri)

      expect(WebMock).to have_requested(:get,uri)
    end

    context "when the response Content-Type contains 'text/xml'" do
      it "must return the parsed XML" do
        stub_request(:get,uri).to_return(
          headers: {'Content-Type' => 'text/xml'},
          body:    xml
        )

        doc = subject.web_get_xml(uri)

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
          subject.web_get_xml(uri)
        }.to raise_error(Ronin::Support::Web::Agent::ContentTypeError,"response 'Content-Type' was not 'text/xml': \"text/plain\"")
      end
    end
  end

  describe "#web_get_json" do
    let(:data) do
      {'foo' => 'bar'}
    end
    let(:json) { data.to_json }

    it "must send a HTTP GET request for the given URI" do
      stub_request(:get,uri).to_return(
        headers: {'Content-Type' => 'application/json'},
        body:    json
      )

      subject.web_get_json(uri)

      expect(WebMock).to have_requested(:get,uri)
    end

    context "when the response Content-Type contains 'application/json'" do
      it "must return the parsed JSON" do
        stub_request(:get,uri).to_return(
          headers: {'Content-Type' => 'application/json'},
          body:    json
        )

        expect(subject.web_get_json(uri)).to eq(data)
      end
    end

    context "when the response Content-Type does not contain 'application/json'" do
      it "must raise an ContentTypeError exception" do
        stub_request(:get,uri).to_return(
          headers: {'Content-Type' => 'text/plain'},
          body:    %{hello world}
        )

        expect {
          subject.web_get_json(uri)
        }.to raise_error(Ronin::Support::Web::Agent::ContentTypeError,"response 'Content-Type' was not 'application/json': \"text/plain\"")
      end
    end
  end

  describe "#web_post" do
    it "must send a HTTP POST request for the given URI and return an Net::HTTPResponse object" do
      stub_request(:post,uri)

      expect(subject.web_post(uri)).to be_kind_of(Net::HTTPResponse)

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

        response = subject.web_post(uri)
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

          response = subject.web_post(uri)
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

          response = subject.web_post(uri, max_redirects: 2)
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
            subject.web_post(uri, max_redirects: 1)
          }.to raise_error(Ronin::Support::Web::Agent::TooManyRedirects,"maximum number of redirects reached: #{uri.inspect}")

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

          response = subject.web_post(uri, follow_redirects: false)
          expect(response).to be_kind_of(Net::HTTPRedirection)
          expect(response['Location']).to eq(redirect_url)
        end
      end
    end
  end

  describe "#web_post_html" do
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

      subject.web_post_html(uri)

      expect(WebMock).to have_requested(:post,uri)
    end

    context "when the response Content-Type contains 'text/html'" do
      it "must return the parsed HTML" do
        stub_request(:post,uri).to_return(
          headers: {'Content-Type' => 'text/html'},
          body:    html
        )

        doc = subject.web_post_html(uri)

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
          subject.web_post_html(uri)
        }.to raise_error(Ronin::Support::Web::Agent::ContentTypeError,"response 'Content-Type' was not 'text/html': \"text/plain\"")
      end
    end
  end

  describe "#web_post_xml" do
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

      subject.web_post_xml(uri)

      expect(WebMock).to have_requested(:post,uri)
    end

    context "when the response Content-Type contains 'text/xml'" do
      it "must return the parsed XML" do
        stub_request(:post,uri).to_return(
          headers: {'Content-Type' => 'text/xml'},
          body:    xml
        )

        doc = subject.web_post_xml(uri)

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
          subject.web_post_xml(uri)
        }.to raise_error(Ronin::Support::Web::Agent::ContentTypeError,"response 'Content-Type' was not 'application/json': \"text/plain\"")
      end
    end
  end

  describe "#web_post_json" do
    let(:data) do
      {'foo' => 'bar'}
    end
    let(:json) { data.to_json }

    it "must send a HTTP POST request for the given URI" do
      stub_request(:post,uri).to_return(
        headers: {'Content-Type' => 'application/json'},
        body:    json
      )

      subject.web_post_json(uri)

      expect(WebMock).to have_requested(:post,uri)
    end

    context "when the response Content-Type contains 'application/json'" do
      it "must return the parsed JSON" do
        stub_request(:post,uri).to_return(
          headers: {'Content-Type' => 'application/json'},
          body:    json
        )

        expect(subject.web_post_json(uri)).to eq(data)
      end
    end

    context "when the response Content-Type does not contain 'application/json'" do
      it "must raise an ContentTypeError exception" do
        stub_request(:post,uri).to_return(
          headers: {'Content-Type' => 'text/plain'},
          body:    %{hello world}
        )

        expect {
          subject.web_post_json(uri)
        }.to raise_error(Ronin::Support::Web::Agent::ContentTypeError,"response 'Content-Type' was not 'application/json': \"text/plain\"")
      end
    end
  end
end
