class IdsToDb
  require 'xmlsimple'
  
  def initialize(client, file_name)
    @client = client
    @file_name = file_name
  end

  def array_from_id_file
    array = []
    File.open(@file_name, 'rb').readlines.each do |line|
      array.push(*line.split(" "))
    end
    array
  end
  
  def generate_xml
    ids = array_from_id_file
    api_key = NPR.config.apiKey
    ids.each do |id|
      uri = URI.parse("http://api.npr.org/transcript?id=#{id}&apiKey=#{api_key}")
      xml_data = Net::HTTP.get_response(uri).body
      xml_hash = XmlSimple.xml_in(xml_data)
      array = get_date_and_audio_link(id)
      transcript = Transcript.new(story_id: id, audio_link: array.last, date: array.first, paragraphs: xml_hash['paragraph'])
      transcript.save!
    end
  end
  
  def get_date_and_audio_link(id)
    story = @client.query(
      fields: 'storyDate,audio',
      id: id
    ).list.stories.first
    date = story.storyDate
    audio_link = story.audio.first.instance_variable_get("@formats").mp3s.first.content + '&dl=1'
    return [date, audio_link]
  end
end