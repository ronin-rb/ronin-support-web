require 'spec_helper'
require 'ronin/support/web/websocket/client'

require 'resolv'

describe Ronin::Support::Web::WebSocket::Client do
  describe "integration", :network do
    let(:url)  { 'ws://websocket-echo.com' }
    let(:uri)  { URI.parse(url) }
    let(:host) { uri.host }
    let(:port) { uri.port }
    let(:ip)   { Resolv.getaddress(host) }

    subject { described_class.new(url) }

    after do
      subject.close

      # cool down to avoid rate limiting
      sleep 0.5
    end

    describe "#initialize" do
      context "when given a ws:// URL string" do
        it "must set #url to a URI::WS object" do
          expect(subject.url).to be_kind_of(URI::WS)
          expect(subject.url.to_s).to eq(url)
        end

        it "must initialize #socket to a TCPSocket connected to the host and port 80" do
          expect(subject.socket).to be_kind_of(TCPSocket)
          expect(subject.socket.peeraddr[2]).to eq(ip)
          expect(subject.socket.peeraddr[1]).to eq(80)
        end

        it "must send the WebSocket handshake" do
          expect(subject.handshake_finished?).to be(true)
          expect(subject.handshake_valid?).to be(true)
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
        let(:url) { 'wss://websocket-echo.com' }

        it "must set #url to a URI::WSS object" do
          expect(subject.url).to be_kind_of(URI::WSS)
          expect(subject.url.to_s).to eq(url)
        end

        it "must initialize #socket to an OpenSSL::SSL::SSLSocket connected to the host and port 443" do
          expect(subject.socket).to be_kind_of(OpenSSL::SSL::SSLSocket)
          expect(subject.socket.peeraddr[2]).to eq(ip)
          expect(subject.socket.peeraddr[1]).to eq(443)
        end

        it "must send the WebSocket handshake" do
          expect(subject.handshake_finished?).to be(true)
          expect(subject.handshake_valid?).to be(true)
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

    describe "#send_frame" do
      let(:data) { "hello world" }
      let(:type) { :text }

      it "must send an encoded WebSocket outgoing client text frame to the #socket" do
        subject.send_frame(data)

        echoed_frame = subject.recv_frame

        expect(echoed_frame.data).to eq(data)
        expect(echoed_frame.type).to eq(:text)
      end

      context "when given a type: keyword argument" do
        let(:type) { :binary }

        it "must send an encoded WebSocket outgoing client frame, of the given type, to the #socket" do
          subject.send_frame(data, type: type)

          echoed_frame = subject.recv_frame

          expect(echoed_frame.data).to eq(data)
          expect(echoed_frame.type).to eq(type)
        end
      end
    end

    describe "#send" do
      let(:data) { "hello world" }

      it "must send an encoded WebSocket outgoing client text frame to the #socket" do
        subject.send(data)

        echoed_frame = subject.recv_frame

        expect(echoed_frame.data).to eq(data)
        expect(echoed_frame.type).to eq(:text)
      end
    end

    describe "#recv_frame" do
      let(:message) { "hello world" }

      before { subject.send_frame(message) }

      it "must read an incoming WebSocket client frame from the underlying #socket" do
        frame = subject.recv_frame

        expect(frame).to be_kind_of(WebSocket::Frame::Incoming::Client)
        expect(frame.data).to eq(message)
      end
    end

    describe "#recv" do
      let(:message1) { "hello world" }
      let(:message2) { "foo bar" }

      it "must read the next incoming WebSocket client frame from the underlying #socket and return the frame's data" do
        subject.send_frame(message1)
        expect(subject.recv).to eq(message1)

        subject.send_frame(message2)
        expect(subject.recv).to eq(message2)
      end
    end

    describe "#close" do
      before { subject.close }

      it "must close the underlying #socket" do
        expect(subject.socket).to be_closed
      end
    end

    describe "#closed?" do
      context "when the socket is open" do
        it "must return false" do
          expect(subject.closed?).to be(false)
        end
      end

      context "when the socket is closed" do
        before { subject.close }

        it "must return true" do
          expect(subject.closed?).to be(true)
        end
      end
    end
  end
end
