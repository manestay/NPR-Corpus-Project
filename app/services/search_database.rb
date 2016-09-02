require 'tactful_tokenizer'
require 'csv'

class SearchDatabase
  def initialize(tokenizer = nil, verbose: false)
    @verbose = verbose
    @m = tokenizer || TactfulTokenizer::Model.new
    puts 'training tokenizer...' unless tokenizer
  end

  # use_rows option will return an array of rows, instead of results
  def search(
    phrase,
    transcripts: Transcript.all,
    limit: nil,
    use_rows: false,
    use_regex: false,
    sort_by: 'chrono'
  )
    hit_array = []
    hit_array << { phrase: phrase } if use_rows # save phrase in array
    phrase.downcase!

    transcripts.each do |transcript|
      paragraphs = transcript.paragraphs
      next unless paragraphs # if no paragraphs

      paragraphs.each_with_index do |paragraph, i|
        next unless paragraph # if blank paragraph

        if use_regex
          found = paragraph.downcase =~ /#{phrase}/
        else
          found = phrase.in? paragraph.downcase.split(/[^\w']+/)
        end

        next unless found

        hit_info =
          case use_rows
          when true
            get_hit_info(phrase, paragraph, paragraphs, i)
          when false
            get_sentence(phrase, paragraph, use_regex)
          end

        hit = set_hit(transcript, hit_info, i, use_rows)

        hit_array << hit

        if @verbose
          sentence = use_rows ? hit_info.last : hit_info
          puts "#{hit_array.size - 1}. #{transcript.title}
          #{sentence}"
        end

        return hit_array if limit && hit_array.size - 1 == limit
      end
    end

    hit_array =
      if sort_by == 'kwicl'
        kwic_sort(phrase, hit_array, -1)
      elsif sort_by == 'kwicr'
        kwic_sort(phrase, hit_array, 1)
      else
        hit_array
      end
  end

  # index is relative to the phrase itself, negative is left, positive is right
  def kwic_sort(phrase, results, index)
    index -= 1 if index > 0

    results.sort_by do |result|

      parts = result.sentence.downcase.partition(phrase)

      part = index < 0 ? parts.first : parts.last

      part.strip.split(/[^[[:word:]]]+/)[index] || 'z'
    end
  end

  private

  def set_hit(transcript, hit_info, i, use_rows)
    return Result.new(
      paragraph_index: i,
      sentence: hit_info,
      transcript: transcript
    ) unless use_rows # return a Result object

    [
      i,
      transcript.title,
      transcript.url_link,
      transcript.audio_link,
      hit_info[0],
      hit_info[1],
      hit_info[2],
      hit_info[3],
      hit_info[4]
    ]
  end

  def get_hit_info(phrase, paragraph, paragraphs, i)
    context = get_context(paragraphs, i)
    follow1 = get_follow1(paragraphs, i)
    follow2 = get_follow2(paragraphs, i)
    sentence = get_sentence(phrase, paragraph)
    # do not write if there was an error

    [context, paragraph, follow1, follow2, sentence]
  end

  def get_context(paragraphs, i)
    return '' if i.zero?
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

  def get_sentence(phrase, paragraph, use_regex)
    sentences = @m.tokenize_text(paragraph)
    sentences.each do |sentence|
      if !use_regex
        return sentence if phrase.in? sentence.downcase
      else
        return sentence if sentence.downcase =~ /#{phrase}/
      end
    end

    # if no sentence is returned, return nil
    Rails.logger.error("sentence not found for #{phrase}, #{paragraph}")
    nil
  end
end
