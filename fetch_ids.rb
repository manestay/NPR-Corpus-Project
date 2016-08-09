class IdScraper
  attr_reader :story_ids

  def initialize(client, start_date: Date.new(2006, 1, 1),
                 end_date: nil, duration: nil, file_name: nil)
    @client = client
    @start_date = start_date
    @end_date = set_end_date(end_date, duration)
    @file_name = file_name
    @story_ids = []
  end

  def run
    skip = 0
    date_index = @start_date
    while date_index <= @end_date
      begin
        response = @client.query(
          fields: 'transcript,storyDate',
          numResults: '50',
          startDate: date_index.to_s,
          endDate: date_index.to_s,
          startNum: skip,
          sort: 'dateAsc'
        )
        batch = response.list.stories
        add_transcript_ids_for batch
        if batch.size == 50 # still more to process
          skip += 50
        else
          skip = 0
          puts "finished #{date_index.to_date}"
          date_index += 1.day
          sleep(1)
        end
      rescue NPR::APIError
        Rails.logger.error("There was an API error for #{date_index}\n")
        date_index += 1.day
      rescue NoMethodError
        Rails.logger.error("There was a no method error for #{date_index}\n")
        date_index += 1.day
      end
    end
  ensure
    date_index -= 1.day
    puts "found #{@story_ids.size} transcripts from #{@start_date.to_date}" \
    " to #{date_index.to_date}"
    write_to_file(date_index) if @story_ids.presence
  end

  def add_transcript_ids_for(stories)
    stories.each do |story|
      next unless story.transcript

      if @story_ids.exclude? story.id
        @story_ids << story.id
        puts "added #{story.id}, #{story.storyDate}"
      else
        puts "#{story.id} already scraped"
      end
    end
  end

  private

  def set_end_date(end_date, duration)
    return end_date if end_date

    return @start_date + duration if duration

    Date.current
  end

  def write_to_file(date_index)
    File.open(file_name(date_index), 'ab') do |f|
      @story_ids.each { |id| f << "#{id} " }
    end
  end

  def file_name(date_index)
    return @file_name if @file_name
    "ids-#{@start_date.to_date}-to-#{date_index.to_date}.txt"
  end
end
