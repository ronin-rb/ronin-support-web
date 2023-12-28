require 'spec_helper'
require 'ronin/support/web/websocket'
require 'ronin/support/web/websocket/server'

describe Ronin::Support::Web::WebSocket do
  let(:url)  { 'ws://websocket-echo.com' }
  let(:uri)  { URI.parse(url) }
  let(:host) { uri.host }
  let(:port) { uri.port }
  let(:ip)   { Resolv.getaddress(host) }

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

  describe ".open?" do
    describe "integration", :network do
      after do
        # cool down to avoid rate limiting
        sleep(0.5)
      end

      context "when the websocket port is open" do
        include_examples "WebSocket Server"

        let(:url) { server_url }

        it "must return true" do
          expect(subject.open?(url)).to be(true)
        end
      end

      context "when the websocket port is not open" do
        include_examples "WebSocket Server"

        let(:url) { "ws://#{server_host}:#{server_port + 1}" }

        it "must return false" do
          expect(subject.open?(url)).to be(false)
        end
      end

      context "when the websocket port is firewalled" do
        let(:url) { "ws://websocket-echo.com:1234" }

        it "must return nil" do
          expect(subject.open?(url)).to be(nil)
        end

        context "when given a timeout" do
          it "must have a timeout for firewalled ports" do
            timeout = 2

            t1 = Time.now
            subject.open?(url, timeout: timeout)
            t2 = Time.now

            expect((t2 - t1).to_i).to be <= timeout
          end
        end
      end

      context "when given a 'wss://' WebSocket URI" do
        let(:url) { "wss://websocket-echo.com" }

        it "must return true" do
          expect(subject.open?(url)).to be(true)
        end
      end
    end

    context "when given a non-WebSocket URI" do
      let(:url) { "http://websocket-echo.com" }

      it do
        expect {
          subject.open?(url)
        }.to raise_error(ArgumentError,"unsupported WebSocket URI scheme: #{url.inspect}")
      end
    end
  end

  describe ".connect" do
    describe "integration", :network do
      after do
        # cool down to avoid rate limiting
        sleep(0.5)
      end

      it "must connect to the WebSocket and return a #{described_class}::Client object" do
        client = subject.connect(url)

        expect(client).to be_kind_of(described_class::Client)
        expect(client.socket).to_not be_closed

        client.close
      end

      context "and when the bind_port: keyword argument is given" do
        let(:bind_port) { 1024 + rand(65535 - 1024) }

        it "must bind to the local port" do
          client     = subject.connect(url, bind_port: bind_port)
          bound_port = client.socket.addr[1]

          expect(bound_port).to eq(bind_port)

          client.close
        end
      end

      context "and when given a block" do
        it "must connect to the WebSocket, yield a new #{described_class}::Client object, then close it" do
          yielded_client = nil

          subject.connect(url) do |client|
            yielded_client = client
          end

          expect(yielded_client).to be_kind_of(described_class::Client)
          expect(yielded_client.socket).to be_closed
        end

        context "and when the bind_port: keyword argument is given" do
          let(:bind_port) { 1024 + rand(65535 - 1024) }

          it "must bind to the local port" do
            bound_port = nil

            subject.connect(url, bind_port: bind_port) do |client|
              bound_port = client.socket.addr[1]
            end

            expect(bound_port).to eq(bind_port)
          end
        end
      end
    end
  end

  describe ".connect_and_send" do
    let(:data) { 'hello world' }

    describe "integration", :network do
      after do
        # cool down to avoid rate limiting
        sleep(0.5)
      end

      it "must connect to the WebSocket, send the data, and return a #{described_class}::Client" do
        client = subject.connect_and_send(data,url)

        expect(client).to be_kind_of(described_class::Client)
        expect(client.recv).to eq(data)
      end

      context "and when the bind_port: keyword argument is given" do
        let(:bind_port) { 1024 + rand(65535 - 1024) }

        it "must bind to the local port" do
          client     = subject.connect_and_send(data,url, bind_port: bind_port)
          bound_port = client.socket.addr[1]

          expect(bound_port).to eq(bind_port)

          client.close
        end
      end

      context "when given a block" do
        it "must connect to the WebSocket and yield a new #{described_class}::Client object" do
          yielded_client = nil

          subject.connect_and_send(data,url) do |client|
            yielded_client = client
          end

          expect(yielded_client).to be_kind_of(described_class::Client)
          expect(yielded_client.socket).to_not be_closed
        end

        context "and when the bind_port: keyword argument is given" do
          let(:bind_port) { 1024 + rand(65535 - 1024) }

          it "must bind to the local port" do
            bound_port = nil

            subject.connect_and_send(data,url, bind_port: bind_port) do |client|
              bound_port = client.socket.addr[1]
            end

            expect(bound_port).to eq(bind_port)
          end
        end
      end
    end
  end

  describe ".send" do
    describe "integration", :network do
      include_context "WebSocket Server"

      let(:data) { "hello world" }
      let(:url)  { server_url }

      it "must send data to a websocket" do
        Thread.new { subject.send(data,server_url) }

        client = server.accept
        sent   = client.recv

        client.close

        expect(sent).to eq(data)
      end

      context "when given a local host and port" do
        let(:bind_port) { 1024 + rand(65535 - 1024) }

        it "must bind to a local host and port" do
          Thread.new do
            subject.send(
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

  describe ".server" do
    describe "integration", :network do
      let(:server_host) { 'localhost' }
      let(:server_port) { 1024 + rand(65535 - 1024) }
      let(:server_url)  { "ws://#{server_host}:#{server_port}" }
      let(:server_uri)  { URI.parse(server_url) }

      it "must create a new #{described_class}::Server" do
        server = subject.server(server_url)

        expect(server).to be_kind_of(described_class::Server)
        expect(server).not_to be_closed
        expect(server.url).to eq(server_uri)

        server.close
      end

      context "when given a block" do
        it "must yield the new #{described_class}::Server and then close it" do
          yielded_server = nil

          subject.server(server_url) do |server|
            yielded_server = server
          end

          expect(yielded_server).to be_kind_of(described_class::Server)
          expect(yielded_server).to be_closed
          expect(yielded_server.url).to eq(server_uri)

          yielded_server.close
        end
      end
    end
  end

  describe ".server_loop" do
    describe "integration", :network
  end

  describe ".accept" do
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

          subject.accept(server_url) do |client|
            yielded_client = client
          end

          expect(yielded_client).to be_kind_of(described_class::Server::Client)
          expect(yielded_client).to be_closed
        end
      end
    end
  end
end
