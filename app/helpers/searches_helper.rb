module SearchesHelper
  def generate_csv(result_array, phrase = nil, time = Time.now, file_name: nil)
    require 'csv'

    file_name ||= "results-#{phrase}-#{time.strftime('%F-%H-%M')}.csv"
    phrase ||= results_array.first.search.phrase rescue nil

    dir = "#{Rails.root}/#{ENV['CSV_FOLDER']}"
    file_location = "#{dir}/#{file_name}"

    return file_location if File.exists? file_location # csv exists already

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
        transcript = result.transcript
        index = result.paragraph_index
        hit = [
          i,
          transcript.title,
          transcript.url_link,
          transcript.audio_link,
          get_context(transcript.paragraphs, index),
          result.paragraph,
          get_follow1(transcript.paragraphs, index),
          get_follow2(transcript.paragraphs, index),
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

  def get_context(paragraphs, i)
    return '' if i == 0
    paragraphs[i - 1]
  end

  def get_follow1(paragraphs, i)
    return '' if i + 1 == paragraphs.size
    paragraphs[i + 1]
  end

  def get_follow2(paragraphs, i)
    return '' if [i + 1, i + 2].include? paragraphs.size
    paragraphs[i + 2]
  end
end
