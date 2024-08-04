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

require_relative 'url_methods'

module Ronin
  module Support
    module Web
      module WebSocket
        #
        # Base class for all WebSockets.
        #
        # @abstract
        #
        # @api private
        #
        class Socket

          # The underlying socket.
          #
          # @return [TCPSocket, OpenSSL::SSL::SSLSocket]
          attr_reader :socket

          # The WebSocket handshake information.
          #
          # @return [::WebSocket::Handshake::Client, WebSocket::Handshake::Server]
          attr_reader :handshake

          #
          # Indicates whether the handshake has finished.
          #
          # @return [Boolean]
          #
          # @api public
          #
          def handshake_finished?
            @handshake.finished?
          end

          #
          # Indicates whether the handshake was valid.
          #
          # @return [Boolean]
          #
          # @api public
          #
          def handshake_valid?
            @handshake.valid?
          end

          #
          # Sends a data frame.
          #
          # @param [#to_s] data
          #   The data to send.
          #
          # @param [:text, :binary, :ping, :pong, :close] type
          #   The data frame type.
          #
          # @api public
          #
          def send_frame(data, type: :text)
            outgoing_frame = @outgoing_frame_class.new(
                               version: @handshake.version,
                               data:    data,
                               type:    type
                             )

            @socket.write(outgoing_frame.to_s)
          end

          #
          # Sends a data frame.
          #
          # @param [#to_s] data
          #   The data to send.
          #
          # @param [Hash{Symbol => Object}] kwargs
          #   Additional keyword arguments for {#send_frame}.
          #
          # @option kwargs [:text, :binary, :ping, :pong, :close] :type (:text)
          #   The data frame type.
          #
          # @api public
          #
          # @see #send_frame
          #
          def send(data,**kwargs)
            send_frame(data,**kwargs)
          end

          #
          # Receives a data frame from the WebSocket.
          #
          # @return [WebSocket::Frame::Incoming::Client,
          #          WebSocket::Frame::Incoming::Server]
          #   The received websocket data frame.
          #
          # @api public
          #
          def recv_frame
            frame = @incoming_frame_class.new(version: @handshake.version)

            begin
              # read data into the input frame
              frame << @socket.readpartial(1024)
            rescue EOFError
              return nil
            end

            return frame.next
          end

          #
          # Receives a data frame.
          #
          # @return [String, nil]
          #
          # @api public
          #
          def recv
            data = recv_frame.data
            data unless data.empty?
          end

          #
          # Closes the socket.
          #
          # @api public
          #
          def close
            @socket.close
          end

          #
          # Determines if the socket is closed.
          #
          # @return [Boolean]
          #
          # @api public
          #
          def closed?
            @socket.closed?
          end

          private

          #
          # Sets the frame classes to use.
          #
          # @param [Class<WebSocket::Frame::Incoming::Client>,
          #         Class<WebSocket::Frame::Incoming::Server>] incoming_frame_class
          #
          # @param [Class<WebSocket::Frame::Outgoing::Client>,
          #         Class<WebSocket::Frame::Outgoing::Server>] outgoing_frame_class
          #
          # @api private
          #
          def set_frame_classes(incoming_frame_class,outgoing_frame_class)
            @incoming_frame_class = incoming_frame_class
            @outgoing_frame_class = outgoing_frame_class
          end

        end
      end
    end
  end
end
