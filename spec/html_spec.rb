require 'spec_helper'
require 'ronin/support/web/html'

describe Ronin::Support::Web::HTML do
  describe ".parse" do
    let(:html) do
      <<~HTML
        <html>
          <body>Hello</body>
        </html>
      HTML
    end

    it "must parse an HTML String and return a Nokogiri::HTML::Document" do
      doc = subject.parse(html)

      expect(doc).to be_kind_of(Nokogiri::HTML::Document)

      # XXX: nokogiri's java extensions behave differently from libxml2
      if RUBY_ENGINE == 'jruby'
        expect(doc.at('body').inner_text).to eq("Hello\n")
      else
        expect(doc.at('body').inner_text).to eq("Hello")
      end
    end

    context "when given a block" do
      it "must yield the Nokogiri::HTML::Document object" do
        expect { |b|
          subject.parse(html,&b)
        }.to yield_with_args(Nokogiri::HTML::Document)
      end
    end
  end

  describe ".build" do
    it "must build an HTML document" do
      doc = subject.build do
        html {
          body {
            div { text("hello") }
          }
        }
      end

      expect(doc.to_html).to include("<html><body><div>hello</div></body></html>")
    end
  end
end
