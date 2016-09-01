json.array!(@transcripts) do |transcript|
  json.extract! transcript, :id, :paragraphs, :date, :story_link, :audio_link, :text
  json.url transcript_url(transcript, format: :json)
end
