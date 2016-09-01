class Result
  include Mongoid::Document
  field :sentence, type: String
  field :paragraph_index, type: Integer

  belongs_to :transcript
  belongs_to :search

  def paragraph
    transcript.paragraphs[paragraph_index]
  end
end
