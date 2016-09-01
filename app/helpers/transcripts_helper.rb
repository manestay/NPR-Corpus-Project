module TranscriptsHelper
  require 'builder'

  def generate_xml(transcript, file_name: nil)
    file = File.new("#{transcript.title}.xml", 'wb') if file_name

    puts 'no transcript' unless transcript
    options = { indent: 2 }
    options.store(:target, file_name) if file_name

    xml = Builder::XmlMarkup.new(options)

    data = xml.document do
      xml.title transcript.title
      xml.date transcript.date.strftime('%B %-d, %Y')
      xml.urllink transcript.url_link
      xml.transcript do
        transcript.paragraphs.each_with_index do |paragraph, i|
          xml.paragraph(paragraph, num: i)
        end
      end
    end

    if file_name
      puts "XML written to #{transcript.title}.xml"
      file.close
    else
      data
    end
  end
end
