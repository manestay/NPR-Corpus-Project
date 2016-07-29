class Transcript
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :story_id, type: String
  field :title, type: String
  field :date, type: Date
  field :story_link, type: String
  field :audio_link, type: String
  field :paragraphs, type: Array
  
  def api_link
    "http://api.npr.org/transcript?id=#{story_id}&apiKey=#{api_key}"
  end
  
  def html_link
    "http://www.npr.org/templates/transcript/transcript.php?storyId=#{story_id}"
  end
  
  def story_link
    "http://www.npr.org/templates/story/story.php?storyId=#{story_id}"
  end
end
