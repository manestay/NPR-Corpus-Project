class Result
  include Mongoid::Document
  field :title, type: String
  field :url_link, type: String
  field :audio_link, type: String
  field :context, type: String
  field :paragraph, type: String
  field :follow1, type: String
  field :follow2, type: String
  field :sentence, type: String

  belongs_to :search
end
