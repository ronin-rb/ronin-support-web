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

require_relative 'web/xml'
require_relative 'web/html'
require_relative 'web/mixin'
require_relative 'web/version'

module Ronin
  module Support
    #
    # Top-level namespace for `ronin-support-web`.
    #
    # ## Example
    #
    #     require 'ronin/support/web'
    #     include Ronin::Support::Web
    #
    #     html_parse "<html>...</html>"
    #     # => #<Nokogiri::HTML::Document: ...>
    #
    module Web
      include Mixin
    end
  end
end
