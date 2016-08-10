class IdsToDb
  API_KEY = ENV['NPR_API_KEY']

  attr_reader :array, :file_name

  def initialize(client, file_name)
    @client = client
    @file_name = file_name
  end

  def array_from_id_file
    return @array if @array
    @array = []
    File.open(@file_name, 'rb').readlines.each do |line|
      @array.concat(line.split(' '))
    end
    @array
  end

  def write_to_database
    ids = array_from_id_file
    count = 0
    ids.each do |id|
      if Transcript.where(story_id: id).first.nil?
        xml = parse_xml(id)
        paragraphs = xml['paragraph'].map(&:squish)
        array = get_title_date_and_audio_link(id)
        puts "Adding story #{id}"

        transcript = Transcript.new(
          story_id: id,
          title: array.first,
          date: array.second,
          url_link: xml['story']['link'].first,
          audio_link: array.third,
          paragraphs: paragraphs
        )
        transcript.save!
        count += 1
      else
        puts "Story #{id} was already in database, not modified"
      end
    end
    puts "Added #{count} transcripts to database"
  end

  def parse_xml(id)
    uri = URI.parse("http://api.npr.org/transcript?id=#{id}&apiKey=#{API_KEY}")
    xml_data = Net::HTTP.get_response(uri).body
    Hash.from_xml(xml_data)['transcript']
  end

  def get_title_date_and_audio_link(id)
    story = @client.query(
      fields: 'title,storyDate,audio',
      id: id
    ).list.stories.first

    title = story.title
    date = story.storyDate
    audio_link = get_audio_link(story.audio)
    Rails.logger.error "Audio not found for #{id}" if audio_link.nil?
    [title, date, audio_link]
  end

  def get_audio_link(audio_array)
    case audio_array.size
    when 0
      return
    when 1
      mp3 = audio_array.first.formats.mp3s.first
      return unless mp3
      mp3.content.sub(/\?.*/, '?dl=1')
    else
      index = audio_array.map(&:type).index('primary')
      return unless index
      mp3 = audio_array[index].formats.mp3s.first
      return unless mp3
      mp3.content.sub(/\?.*/, '?dl=1')
    end
  end
end
