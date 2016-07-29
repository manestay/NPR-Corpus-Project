class IdScraper
  attr_reader :story_ids
  
  def initialize(client, start_date: Time.new(2006,01,01),  duration: 1.year)
    @client = client
    @start_date = start_date
    @duration = duration
    @end_date = start_date + duration
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
          startDate: time_string(date_index),
          endDate: time_string(date_index),
          startNum: skip,
          sort: 'dateAsc'
         )
        batch = response.list.stories
        add_transcript_ids_for batch
        if batch.size == 50 # still more to process
          skip += 50
        else
          skip = 0
          puts "finished  #{time_string(date_index)}"
          date_index += 1.day
          sleep(1)
        end
      rescue NPR::APIError
        ::Rails.logger.error("There was an API error for #{time_string date_index}\n")
          date_index += 1.day
      rescue NoMethodError
        ::Rails.logger.error("There was a no method error for #{time_string date_index}\n")
          date_index += 1.day
      end
    end
  ensure
     puts "done finding #{@story_ids.size} transcripts for #{time_string @start_date} to  #{time_string @end_date} "
     write_to_file if @story_ids.presence
  end
  
  def add_transcript_ids_for(stories)    
    stories.each do |story|
      if story.transcript
        @story_ids << story.id
        puts "added #{story.id}, #{time_string(story.storyDate)}"
      end
    end
  end  
  
  def time_string(time)
      time.strftime('%Y-%m-%d') 
  end
  
  private
  
  def write_to_file
    File.open("ids-#{Time.now.strftime('%s')}.txt", 'ab') do |f|
      @story_ids.each { |id| f << "#{id} "}
     end
  end
end

client = NPR::API::Client.new
scrape = IdScraper.new(client, start_date: Time.new(2007,04,18), duration: 9.years)
scrape.run