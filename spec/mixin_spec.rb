require 'spec_helper'
require 'ronin/support/web/mixin'

describe Ronin::Support::Web::Mixin do
  subject do
    Class.new { include Ronin::Support::Web::Mixin }
  end

  it "must include `Ronin::Support::Web::HTML::Mixin`" do
    expect(subject).to include(Ronin::Support::Web::HTML::Mixin)
  end

  it "must include `Ronin::Support::Web::XML::Mixin`" do
    expect(subject).to include(Ronin::Support::Web::XML::Mixin)
  end

  it "must include `Ronin::Support::Web::Agent::Mixin`" do
    expect(subject).to include(Ronin::Support::Web::Agent::Mixin)
  end
end
