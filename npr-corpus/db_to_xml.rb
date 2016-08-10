require 'builder'

class DbToXml
  def initialize(output_to_stdout = false)
    @output_to_stdout = output_to_stdout
  end

  def generate_xmls(transcripts)
    transcripts.each { |transcript| generate_xml(transcript) }
  end

  def generate_xml(transcript)
    target =
      if @output_to_stdout
        '$stdout'
      else
        File.new("#{transcript.title}.xml", 'wb')
      end

    xml = Builder::XmlMarkup.new(target: target, indent: 2)

    xml.document do
      xml.title transcript.title
      xml.date transcript.date.strftime('%B %-d, %Y')
      xml.urllink transcript.url_link
      xml.transcript do
        transcript.paragraphs.each_with_index do |paragraph, i|
          xml.paragraph(paragraph, num: i)
        end
      end
    end
  end
end
