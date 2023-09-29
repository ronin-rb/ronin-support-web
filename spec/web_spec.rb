require 'spec_helper'
require 'ronin/support/web'

describe Ronin::Support::Web do
  it "must have a version" do
    expect(subject.const_defined?('VERSION')).to be(true)
  end

  it "must include Ronin::Support::Web::Mixin" do
    expect(subject).to include(Ronin::Support::Web::Mixin)
  end
end
