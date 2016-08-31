class Result
  include Mongoid::Document
  field :transcript_id, type: String
  field :title, type: String
  field :url_link, type: String
  field :audio_link, type: String
  field :context, type: String
  field :paragraph, type: String # TODO: remove fields besides paragraph and use index for context and follows
  field :follow1, type: String
  field :follow2, type: String
  field :sentence, type: String

  belongs_to :search
end
