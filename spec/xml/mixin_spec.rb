require 'spec_helper'
require 'ronin/support/web/xml/mixin'

describe Ronin::Support::Web::XML::Mixin do
  subject do
    obj = Object.new
    obj.extend described_class
    obj
  end

  let(:fixtures_dir) { File.join(__dir__,'..','fixtures') }
  let(:xml_file)     { File.join(fixtures_dir,'test.xml') }
  let(:xml)          { File.read(xml_file) }

  describe "#xml_parse" do
    it "must parse an XML String and return a Nokogiri::XML::Document" do
      doc = subject.xml_parse(xml)

      expect(doc).to be_kind_of(Nokogiri::XML::Document)

      # XXX: nokogiri's java extensions behave differently from libxml2
      if RUBY_ENGINE == 'jruby'
        expect(doc.to_s).to eq(xml.chomp)
      else
        expect(doc.to_s).to eq(xml)
      end
    end

    context "when given a block" do
      it "must yield the Nokogiri::XML::Document object" do
        expect { |b|
          subject.xml_parse(xml,&b)
        }.to yield_with_args(Nokogiri::XML::Document)
      end
    end
  end

  describe ".open" do
    it "must open and parse the given path, and return a Nokogiri::XML::Document" do
      doc = subject.xml_open(xml_file)

      expect(doc).to be_kind_of(Nokogiri::XML::Document)

      # XXX: nokogiri's java extensions behave differently from libxml2
      if RUBY_ENGINE == 'jruby'
        expect(doc.to_s).to eq(xml.chomp)
      else
        expect(doc.to_s).to eq(xml)
      end
    end

    context "when given a block" do
      it "must yield the Nokogiri::XML::Document object" do
        expect { |b|
          subject.xml_open(xml_file,&b)
        }.to yield_with_args(Nokogiri::XML::Document)
      end
    end
  end

  describe "#xml_build" do
    it "must build an XML document" do
      doc = subject.xml_build do |xml|
        xml.root {
          xml.stuff(name: 'bla') { xml.text("hello") }
        }
      end

      expect(doc.to_xml).to include("<root>\n  <stuff name=\"bla\">hello</stuff>\n</root>")
    end
  end
end
