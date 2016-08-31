module SearchHelper
  def generate_csv(result_array, phrase = nil, time = nil, file_name: nil)
    require 'csv'

    file_name ||= "results-#{phrase}-#{time.strftime('%F-%H-%M')}.csv"

    dir = "#{Rails.root}/#{ENV['CSV_FOLDER']}"
    file_location = "#{dir}/#{file_name}"

    return file_location if File.exists? file_location

    CSV.open(file_location, 'wb') do |csv|
      csv << [ # header
        'Number',
        'Title',
        'Trans link',
        'Audio link',
        'Context',
        'Paragraph',
        'Continuation',
        'Continuation2',
        'Sentence',
        "phrase: #{phrase}"
      ]

      result_array.each.with_index(1) do |result, i|
        hit = [
          i,
          result.title,
          result.url_link,
          result.audio_link,
          result.context,
          result.paragraph,
          result.follow1,
          result.follow2,
          result.sentence
        ]

        csv << hit
      end
    end
    file_location

  rescue StandardError => ex
    puts "There was an error: #{ex}"
  end

  def get_transcript_id(result)
    return result.transcript_id if result.transcript_id
    Transcript.where(title: result.title).first.id
  end
end
