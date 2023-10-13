require 'spec_helper'
require 'ronin/support/web/html'

describe Ronin::Support::Web::HTML do
  let(:fixtures_dir) { File.join(__dir__,'fixtures') }
  let(:html_file)    { File.join(fixtures_dir,'test.html') }
  let(:html)         { File.read(html_file) }

  describe ".parse" do
    it "must parse an HTML String and return a Nokogiri::HTML::Document" do
      doc = subject.parse(html)

      expect(doc).to be_kind_of(Nokogiri::HTML::Document)

      # XXX: nokogiri's java extensions behave differently from libxml2
      if RUBY_ENGINE == 'jruby'
        expect(doc.to_s).to eq(
          <<~HTML
            <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
            #{html}
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

    context "when given a block" do
      it "must yield the Nokogiri::HTML::Document object" do
        expect { |b|
          subject.parse(html,&b)
        }.to yield_with_args(Nokogiri::HTML::Document)
      end
    end
  end

  describe ".open" do
    it "must open and parse the given path, and return a Nokogiri::HTML::Document" do
      doc = subject.open(html_file)

      expect(doc).to be_kind_of(Nokogiri::HTML::Document)

      # XXX: nokogiri's java extensions behave differently from libxml2
      if RUBY_ENGINE == 'jruby'
        expect(doc.to_s).to eq(
          <<~HTML
            <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
            #{html}
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

    context "when given a block" do
      it "must yield the Nokogiri::HTML::Document object" do
        expect { |b|
          subject.open(html_file,&b)
        }.to yield_with_args(Nokogiri::HTML::Document)
      end
    end
  end

  describe ".build" do
    it "must build an HTML document" do
      doc = subject.build do |html|
        html.html {
          html.body {
            html.div { html.text("hello") }
          }
        }
      end

      expect(doc.to_html).to include("<html><body><div>hello</div></body></html>")
    end
  end
end
