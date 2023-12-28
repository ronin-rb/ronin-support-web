require 'spec_helper'
require 'ronin/support/web/websocket/mixin'
require 'ronin/support/web/websocket/server'

describe Ronin::Support::Web::WebSocket::Mixin do
  let(:url)  { 'ws://websocket-echo.com' }
  let(:uri)  { URI.parse(url) }
  let(:host) { uri.host }
  let(:port) { uri.port }
  let(:ip)   { Resolv.getaddress(host) }

  class TestWebSocketMixin
    include Ronin::Support::Web::WebSocket::Mixin
  end

  subject { TestWebSocketMixin.new }

  shared_examples "WebSocket Server" do
    let(:server_host) { 'localhost' }
    let(:server_ip)   { Resolv.getaddress(server_host) }
    let(:server_port) { 1024 + rand(65535 - 1024) }
    let(:server_url)  { "ws://#{server_host}:#{server_port}" }
    let(:server) do
      Ronin::Support::Web::WebSocket::Server.new(server_url)
    end
    let(:server_bind_ip)   { server.socket.addr[3] }
    let(:server_bind_port) { server.socket.addr[1] }

    before(:each) { server.listen(1) }
    after(:each)  { server.close }
  end

  describe "#websocket_open?" do
    describe "integration", :network do
      context "when the websocket port is open" do
        include_examples "WebSocket Server"

        let(:url) { server_url }

        it "must return true" do
          expect(subject.websocket_open?(url)).to be(true)
        end
      end

      context "when the websocket port is not open" do
        include_examples "WebSocket Server"

        let(:url) { "ws://#{server_host}:#{server_port + 1}" }

        it "must return false" do
          expect(subject.websocket_open?(url)).to be(false)
        end
      end

      context "when the websocket port is firewalled" do
        let(:url) { "ws://websocket-echo.com:1234" }

        it "must return nil" do
          expect(subject.websocket_open?(url)).to be(nil)
        end

        context "when given a timeout" do
          it "must have a timeout for firewalled ports" do
            timeout = 2

            t1 = Time.now
            subject.websocket_open?(url, timeout: timeout)
            t2 = Time.now

            expect((t2 - t1).to_i).to be <= timeout
          end
        end
      end

      context "when given a 'wss://' WebSocket URI" do
        let(:url) { "wss://websocket-echo.com" }

        it "must return true" do
          expect(subject.websocket_open?(url)).to be(true)
        end
      end
    end

    context "when given a non-WebSocket URI" do
      let(:url) { "http://websocket-echo.com" }

      it do
        expect {
          subject.websocket_open?(url)
        }.to raise_error(ArgumentError,"unsupported WebSocket URI scheme: #{url.inspect}")
      end
    end
  end

  describe "#websocket_connect" do
    describe "integration", :network do
      after do
        # cool down to avoid rate limiting
        sleep(0.5)
      end

      it "must connect to the WebSocket and return a Ronin::Support::Web::WebSocket::Client object" do
        client = subject.websocket_connect(url)

        expect(client).to be_kind_of(Ronin::Support::Web::WebSocket::Client)
        expect(client.socket).to_not be_closed

        client.close
      end

      context "and when the bind_port: keyword argument is given" do
        let(:bind_port) { 1024 + rand(65535 - 1024) }

        it "must bind to the local port" do
          client     = subject.websocket_connect(url, bind_port: bind_port)
          bound_port = client.socket.addr[1]

          expect(bound_port).to eq(bind_port)

          client.close
        end
      end

      context "and when given a block" do
        it "must connect to the WebSocket, yield a new Ronin::Support::Web::WebSocket::Client object, then close it" do
          yielded_client = nil

          subject.websocket_connect(url) do |client|
            yielded_client = client
          end

          expect(yielded_client).to be_kind_of(Ronin::Support::Web::WebSocket::Client)
          expect(yielded_client.socket).to be_closed
        end

        context "and when the bind_port: keyword argument is given" do
          let(:bind_port) { 1024 + rand(65535 - 1024) }

          it "must bind to the local port" do
            bound_port = nil

            subject.websocket_connect(url, bind_port: bind_port) do |client|
              bound_port = client.socket.addr[1]
            end

            expect(bound_port).to eq(bind_port)
          end
        end
      end
    end
  end

  describe "#websocket_connect_and_send" do
    let(:data) { 'hello world' }

    describe "integration", :network do
      after do
        # cool down to avoid rate limiting
        sleep(0.5)
      end

      it "must connect to the WebSocket, send the data, and return a Ronin::Support::Web::WebSocket::Client" do
        client = subject.websocket_connect_and_send(data,url)

        expect(client).to be_kind_of(Ronin::Support::Web::WebSocket::Client)
        expect(client.recv).to eq(data)
      end

      context "and when the bind_port: keyword argument is given" do
        let(:bind_port) { 1024 + rand(65535 - 1024) }

        it "must bind to the local port" do
          client     = subject.websocket_connect_and_send(data,url, bind_port: bind_port)
          bound_port = client.socket.addr[1]

          expect(bound_port).to eq(bind_port)

          client.close
        end
      end

      context "when given a block" do
        it "must connect to the WebSocket and yield a new Ronin::Support::Web::WebSocket::Client object" do
          yielded_client = nil

          subject.websocket_connect_and_send(data,url) do |client|
            yielded_client = client
          end

          expect(yielded_client).to be_kind_of(Ronin::Support::Web::WebSocket::Client)
          expect(yielded_client.socket).to_not be_closed
        end

        context "and when the bind_port: keyword argument is given" do
          let(:bind_port) { 1024 + rand(65535 - 1024) }

          it "must bind to the local port" do
            bound_port = nil

            subject.websocket_connect_and_send(data,url, bind_port: bind_port) do |client|
              bound_port = client.socket.addr[1]
            end

            expect(bound_port).to eq(bind_port)
          end
        end
      end
    end
  end

  describe "#websocket_send" do
    describe "integration", :network do
      include_context "WebSocket Server"

      let(:data) { "hello world" }
      let(:url)  { server_url }

      it "must send data to a websocket" do
        Thread.new { subject.websocket_send(data,server_url) }

        client = server.accept
        sent   = client.recv

        client.close

        expect(sent).to eq(data)
      end

      context "when given a local host and port" do
        let(:bind_port) { 1024 + rand(65535 - 1024) }

        it "must bind to a local host and port" do
          Thread.new do
            subject.websocket_send(
              data, server_url,
              bind_host: server_bind_ip,
              bind_port: bind_port
            )
          end

          client      = server.accept
          client_port = client.socket.peeraddr[1]

          expect(client_port).to eq(bind_port)

          client.close
        end
      end
    end
  end

  describe "#websocket_server" do
    describe "integration", :network do
      let(:server_host) { 'localhost' }
      let(:server_port) { 1024 + rand(65535 - 1024) }
      let(:server_url)  { "ws://#{server_host}:#{server_port}" }
      let(:server_uri)  { URI.parse(server_url) }

      it "must create a new Ronin::Support::Web::WebSocket::Server" do
        server = subject.websocket_server(server_url)

        expect(server).to be_kind_of(Ronin::Support::Web::WebSocket::Server)
        expect(server).not_to be_closed
        expect(server.url).to eq(server_uri)

        server.close
      end

      context "when given a block" do
        it "must yield the new Ronin::Support::Web::WebSocket::Server and then close it" do
          yielded_server = nil

          subject.websocket_server(server_url) do |server|
            yielded_server = server
          end

          expect(yielded_server).to be_kind_of(Ronin::Support::Web::WebSocket::Server)
          expect(yielded_server).to be_closed
          expect(yielded_server.url).to eq(server_uri)

          yielded_server.close
        end
      end
    end
  end

  describe "#websocket_server_loop" do
    describe "integration", :network
  end

  describe "#websocket_accept" do
    describe "integration", :network do
      let(:server_host) { 'localhost' }
      let(:server_port) { 1024 + rand(65535 - 1024) }
      let(:server_url)  { "ws://#{server_host}:#{server_port}" }
      let(:server_uri)  { URI.parse(server_url) }

      context "when a block is given" do
        it "must open a socket for listening and accept a single connection, yield the it, and close it" do
          Thread.new do
            sleep 0.1
            client = Ronin::Support::Web::WebSocket::Client.new(server_url)

            sleep 0.5
            client.close
          end

          yielded_client = nil

          subject.websocket_accept(server_url) do |client|
            yielded_client = client
          end

          expect(yielded_client).to be_kind_of(Ronin::Support::Web::WebSocket::Server::Client)
          expect(yielded_client).to be_closed
        end
      end
    end
  end

  describe "#ws_open?" do
    let(:host) { 'example.com' }

    it "must call WebSocket.connect with a URI::WS for the host" do
      uri = URI::WS.build(host: host)

      expect(Ronin::Support::Web::WebSocket).to receive(:open?).with(uri, {ssl: {}})

      subject.ws_open?(host)
    end

    context "when an additional port argument is given" do
      let(:port) { 8080 }

      it "must add the port to the URI::WS object" do
        uri = URI::WS.build(host: host, port: port)

        expect(Ronin::Support::Web::WebSocket).to receive(:open?).with(uri, {ssl: {}})

        subject.ws_open?(host,port)
      end
    end
  end

  describe "#wss_open?" do
    let(:host) { 'example.com' }

    it "must call WebSocket.connect with a URI::WSS for the host" do
      uri = URI::WSS.build(host: host)

      expect(Ronin::Support::Web::WebSocket).to receive(:open?).with(uri, {ssl: {}})

      subject.wss_open?(host)
    end

    context "when an additional port argument is given" do
      let(:port) { 8080 }

      it "must add the port to the URI::WSS object" do
        uri = URI::WSS.build(host: host, port: port)

        expect(Ronin::Support::Web::WebSocket).to receive(:open?).with(uri, {ssl: {}})

        subject.wss_open?(host,port)
      end
    end
  end

  describe "#ws_connect" do
    let(:host) { 'example.com' }

    it "must call #websocket_connect with a URI::WS for the host" do
      uri = URI::WS.build(host: host)

      expect(Ronin::Support::Web::WebSocket).to receive(:connect).with(uri, {ssl: {}})

      subject.ws_connect(host)
    end

    context "when an additional port argument is given" do
      let(:port) { 8080 }

      it "must add the port to the URI::WS object" do
        uri = URI::WS.build(host: host, port: port)

        expect(Ronin::Support::Web::WebSocket).to receive(:connect).with(uri, {ssl: {}})

        subject.ws_connect(host,port)
      end
    end
  end

  describe "#wss_connect" do
    let(:host) { 'example.com' }

    it "must call WebSocket.connect with a URI::WSS for the host" do
      uri = URI::WSS.build(host: host)

      expect(Ronin::Support::Web::WebSocket).to receive(:connect).with(uri, {ssl: {}})

      subject.wss_connect(host)
    end

    context "when an additional port argument is given" do
      let(:port) { 4343 }

      it "must add the port to the URI::WSS object" do
        uri = URI::WSS.build(host: host, port: port)

        expect(Ronin::Support::Web::WebSocket).to receive(:connect).with(uri, {ssl: {}})

        subject.wss_connect(host,port)
      end
    end
  end

  describe "#ws_connect_and_send" do
    let(:host) { 'example.com' }
    let(:data) { 'hello world' }

    it "must call WebSocket.connect_and_send with a URI::WS for the host" do
      uri = URI::WS.build(host: host)

      expect(Ronin::Support::Web::WebSocket).to receive(:connect_and_send).with(data,uri, {type: :text, ssl: {}})

      subject.ws_connect_and_send(data,host)
    end

    context "when an additional port argument is given" do
      let(:port) { 8080 }

      it "must add the port to the URI::WS object" do
        uri = URI::WS.build(host: host, port: port)

        expect(Ronin::Support::Web::WebSocket).to receive(:connect_and_send).with(data,uri, {type: :text, ssl: {}})

        subject.ws_connect_and_send(data,host,port)
      end
    end
  end

  describe "#wss_connect_and_send" do
    let(:host) { 'example.com' }
    let(:data) { 'hello world' }

    it "must call WebSocket.connect_and_send with a URI::WSS for the host" do
      uri = URI::WSS.build(host: host)

      expect(Ronin::Support::Web::WebSocket).to receive(:connect_and_send).with(data,uri, {type: :text, ssl: {}})

      subject.wss_connect_and_send(data,host)
    end

    context "when an additional port argument is given" do
      let(:port) { 4343 }

      it "must add the port to the URI::WSS object" do
        uri = URI::WSS.build(host: host, port: port)

        expect(Ronin::Support::Web::WebSocket).to receive(:connect_and_send).with(data,uri, {type: :text, ssl: {}})

        subject.wss_connect_and_send(data,host,port)
      end
    end
  end

  describe "#ws_send" do
    let(:data) { "hello world" }
    let(:host) { 'example.com' }

    it "must call WebSocket.send with a URI::WS for the host" do
      uri = URI::WS.build(host: host)

      expect(Ronin::Support::Web::WebSocket).to receive(:send).with(data,uri, {type: :text, ssl: {}})

      subject.ws_send(data,host)
    end

    context "when an additional port argument is given" do
      let(:port) { 8080 }

      it "must add the port to the URI::WS object" do
        uri = URI::WS.build(host: host, port: port)

        expect(Ronin::Support::Web::WebSocket).to receive(:send).with(data,uri, {type: :text, ssl: {}})

        subject.ws_send(data,host,port)
      end
    end
  end

  describe "#wss_send" do
    let(:data) { "hello world" }
    let(:host) { 'example.com' }

    it "must call WebSocket.send with a URI::WSS for the host" do
      uri = URI::WSS.build(host: host)

      expect(Ronin::Support::Web::WebSocket).to receive(:send).with(data,uri, {type: :text, ssl: {}})

      subject.wss_send(data,host)
    end

    context "when an additional port argument is given" do
      let(:port) { 4343 }

      it "must add the port to the URI::WSS object" do
        uri = URI::WSS.build(host: host, port: port)

        expect(Ronin::Support::Web::WebSocket).to receive(:send).with(data,uri, {type: :text, ssl: {}})

        subject.wss_send(data,host,port)
      end
    end
  end

  describe "#ws_server" do
    let(:host) { 'example.com' }

    it "must call WebSocket.server with a URI::WS for the host" do
      uri = URI::WS.build(host: host)

      expect(Ronin::Support::Web::WebSocket).to receive(:server).with(uri, {ssl: {}})

      subject.ws_server(host)
    end

    context "when an additional port argument is given" do
      let(:port) { 8080 }

      it "must add the port to the URI::WS object" do
        uri = URI::WS.build(host: host, port: port)

        expect(Ronin::Support::Web::WebSocket).to receive(:server).with(uri, {ssl: {}})

        subject.ws_server(host,port)
      end
    end
  end

  describe "#wss_server" do
    let(:host) { 'example.com' }

    it "must call WebSocket.server with a URI::WSS for the host" do
      uri = URI::WSS.build(host: host)

      expect(Ronin::Support::Web::WebSocket).to receive(:server).with(uri, {ssl: {}})

      subject.wss_server(host)
    end

    context "when an additional port argument is given" do
      let(:port) { 8080 }

      it "must add the port to the URI::WSS object" do
        uri = URI::WSS.build(host: host, port: port)

        expect(Ronin::Support::Web::WebSocket).to receive(:server).with(uri, {ssl: {}})

        subject.wss_server(host,port)
      end
    end
  end

  describe "#ws_server_loop" do
    let(:host) { 'example.com' }

    it "must call WebSocket.server_loop with a URI::WS for the host" do
      uri = URI::WS.build(host: host)

      expect(Ronin::Support::Web::WebSocket).to receive(:server_loop).with(uri, {ssl: {}})

      subject.ws_server_loop(host)
    end

    context "when an additional port argument is given" do
      let(:port) { 8080 }

      it "must add the port to the URI::WS object" do
        uri = URI::WS.build(host: host, port: port)

        expect(Ronin::Support::Web::WebSocket).to receive(:server_loop).with(uri, {ssl: {}})

        subject.ws_server_loop(host,port)
      end
    end
  end

  describe "#wss_server_loop" do
    let(:host) { 'example.com' }

    it "must call WebSocket.server_loop with a URI::WSS for the host" do
      uri = URI::WSS.build(host: host)

      expect(Ronin::Support::Web::WebSocket).to receive(:server_loop).with(uri, {ssl: {}})

      subject.wss_server_loop(host)
    end

    context "when an additional port argument is given" do
      let(:port) { 4343 }

      it "must add the port to the URI::WSS object" do
        uri = URI::WS.build(host: host, port: port)

        expect(Ronin::Support::Web::WebSocket).to receive(:server_loop).with(uri, {ssl: {}})

        subject.ws_server_loop(host,port)
      end
    end
  end

  describe "#ws_accept" do
    let(:host) { 'example.com' }

    it "must call WebSocket.accept with a URI::WS for the host" do
      uri = URI::WS.build(host: host)

      expect(Ronin::Support::Web::WebSocket).to receive(:accept).with(uri, {ssl: {}})

      subject.ws_accept(host)
    end

    context "when an additional port argument is given" do
      let(:port) { 8080 }

      it "must add the port to the URI::WS object" do
        uri = URI::WS.build(host: host, port: port)

        expect(Ronin::Support::Web::WebSocket).to receive(:accept).with(uri, {ssl: {}})

        subject.ws_accept(host,port)
      end
    end
  end

  describe "#wss_accept" do
    let(:host) { 'example.com' }

    it "must call WebSocket.accept with a URI::WSS for the host" do
      uri = URI::WSS.build(host: host)

      expect(Ronin::Support::Web::WebSocket).to receive(:accept).with(uri, {ssl: {}})

      subject.wss_accept(host)
    end

    context "when an additional port argument is given" do
      let(:port) { 4343 }

      it "must add the port to the URI::WSS object" do
        uri = URI::WSS.build(host: host, port: port)

        expect(Ronin::Support::Web::WebSocket).to receive(:accept).with(uri, {ssl: {}})

        subject.wss_accept(host,port)
      end
    end
  end
end
