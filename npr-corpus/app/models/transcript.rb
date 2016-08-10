class Transcript
  API_KEY = ENV['NPR_API_KEY']
  include Mongoid::Document
  include Mongoid::Timestamps

  field :story_id, type: String
  field :title, type: String
  field :date, type: DateTime
  field :url_link, type: String
  field :audio_link, type: String
  field :paragraphs, type: Array

  def api_link
    "http://api.npr.org/transcript?id=#{story_id}&apiKey=#{ENV['NPR_API_KEY']}"
  end

  def html_link
    "http://www.npr.org/templates/transcript/transcript.php?storyId=#{story_id}"
  end

  def story_link
    "http://www.npr.org/templates/story/story.php?storyId=#{story_id}"
  end

  def story_api_link
    "http://api.npr.org/query?id=#{story_id}&apiKey=#{ENV['NPR_API_KEY']}"
  end
end
