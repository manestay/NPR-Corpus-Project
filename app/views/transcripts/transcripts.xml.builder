xml.instruct!

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