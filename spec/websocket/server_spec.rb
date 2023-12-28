require 'spec_helper'
require 'ronin/support/web/websocket/server'
require 'ronin/support/web/websocket/client'

describe Ronin::Support::Web::WebSocket::Server do
  let(:host) { 'localhost' }
  let(:port) { 1024 + rand(65535 - 1024) }
  let(:url)  { "ws://#{host}:#{port}" }
  let(:uri)  { URI.parse(url) }

  subject { described_class.new(url) }

  after { subject.close }

  describe "#initialize" do
    describe "integration", :network do
      context "when given a ws:// URL string" do
        it "must set #url to a URI::WS object" do
          expect(subject.url).to be_kind_of(URI::WS)
          expect(subject.url.to_s).to eq(url)
        end

        it "must initialize #socket to a TCPServer listening on the URL's host and port" do
          expect(subject.socket).to be_kind_of(TCPServer)
          expect(subject.socket.addr[3]).to eq('0.0.0.0').or(eq('::1'))
          expect(subject.socket.addr[1]).to eq(port)
        end

        context "and when the bind_port: keyword argument is given" do
          let(:bind_port) { 1024 + rand(65535 - 1024) }

          subject { described_class.new(url, bind_port: bind_port) }

          it "must bind the socket to the local port" do
            bound_port = subject.socket.addr[1]

            expect(bound_port).to eq(bind_port)
          end
        end
      end

      context "when given a wss:// URL string" do
        let(:url) { "wss://#{host}:#{port}" }

        it "must set #url to a URI::WSS object" do
          expect(subject.url).to be_kind_of(URI::WSS)
          expect(subject.url.to_s).to eq(url)
        end

        it "must initialize #socket to an OpenSSL::SSL::SSLServer connected to the host and port 443" do
          expect(subject.socket).to be_kind_of(OpenSSL::SSL::SSLServer)
          expect(subject.socket.addr[3]).to eq('0.0.0.0').or(eq('::1'))
          expect(subject.socket.addr[1]).to eq(port)
        end

        context "and when the bind_port: keyword argument is given" do
          let(:bind_port) { 1024 + rand(65535 - 1024) }

          subject { described_class.new(url, bind_port: bind_port) }

          it "must bind the socket to the local port" do
            bound_port = subject.socket.addr[1]

            expect(bound_port).to eq(bind_port)
          end
        end
      end
    end
  end

  describe "#listen" do
    describe "integration", :network do
      subject { described_class.new(url) }

      let(:backlog) { 2 }

      it "must call #socket.listen with the backlog" do
        expect(subject.socket).to receive(:listen).with(backlog)

        subject.listen(backlog)
      end
    end
  end

  describe "#accept" do
    describe "integration", :network do
      subject { described_class.new(url) }

      before { subject.listen(1) }

      it "must accept a new connection and return a #{described_class}::Client" do
        Thread.new do
          client = Ronin::Support::Web::WebSocket::Client.new(url)
          sleep 2
          client.close
        end

        client = subject.accept
        expect(client).to be_kind_of(described_class::Client)
        expect(client).to_not be_closed
      end
    end
  end
end
