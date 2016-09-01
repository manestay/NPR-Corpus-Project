class Search
  include Mongoid::Document
  field :phrase, type: String
  field :submitted_at, type: DateTime
  field :start_date, type: Date, default: Date.new(2006, 1, 1)
  field :end_date, type: Date, default: Date.current
  field :transcript_count, type: Integer
  field :limit, type: Integer, default: nil
  field :regex, type: Boolean, default: false
  field :sort_by, type: String, default: "chrono" # values: chrono, kwicl, kwicr

  has_many :results
  belongs_to :user
end
