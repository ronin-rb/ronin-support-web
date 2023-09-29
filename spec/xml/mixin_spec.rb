require 'spec_helper'
require 'ronin/support/web/xml/mixin'

describe Ronin::Support::Web::XML::Mixin do
  subject do
    obj = Object.new
    obj.extend described_class
    obj
  end

  describe "#xml_parse" do
    let(:xml) do
      <<~XML
        <?xml version="1.0"?>
        <root>
          <stuff>Hello</stuff>
        </root>
      XML
    end

    it "must parse an XML String and return a Nokogiri::XML::Document" do
      doc = subject.xml_parse(xml)

      expect(doc).to be_kind_of(Nokogiri::XML::Document)
      expect(doc.at('stuff').inner_text).to eq("Hello")
    end

    context "when given a block" do
      it "must yield the Nokogiri::XML::Document object" do
        expect { |b|
          subject.xml_parse(xml,&b)
        }.to yield_with_args(Nokogiri::XML::Document)
      end
    end
  end

  describe "#xml_build" do
    it "must build an XML document" do
      doc = subject.xml_build do
        root {
          stuff(name: 'bla') { text("hello") }
        }
      end

      expect(doc.to_xml).to include("<root>\n  <stuff name=\"bla\">hello</stuff>\n</root>")
    end
  end
end
