require 'tactful_tokenizer'
require 'csv'

class SearchDatabase
  def initialize(tokenizer = nil, verbose: false)
    @verbose = verbose
    @m = tokenizer || TactfulTokenizer::Model.new
    puts 'training tokenizer...' unless tokenizer
  end

  # use_rows option will return an array of rows, instead of results
  def search(phrase, transcripts: Transcript.all, limit: nil, use_rows: false)
    hit_array = [{ phrase: phrase }] # save phrase in array
    transcripts.each do |transcript|
      paragraphs = transcript.paragraphs
      next unless paragraphs # if no paragraphs

      paragraphs.each_with_index do |paragraph, i|
        next unless paragraph # if blank paragraph
        next unless phrase.in? paragraph.downcase.split(/[^\w']+/) # if phrase not found

        hit_info =
          case use_rows
          when true
            get_hit_info(phrase, paragraph, paragraphs, i)
          when false
            get_sentence(phrase, paragraph)
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
    hit_array
  end

  def search_plain(phrase, transcripts: Transcript.all, limit: nil)
    search(phrase, transcripts, limit, use_rows: true)
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
    context = get_context(phrase, paragraphs, i)
    follow1 = get_follow1(phrase, paragraphs, i)
    follow2 = get_follow2(phrase, paragraphs, i)
    sentence = get_sentence(phrase, paragraph)
    # do not write if there was an error

    [context, paragraph, follow1, follow2, sentence]
  end

  def get_context(phrase, paragraphs, i)
    return '' if i == 0
    paragraphs[i - 1]
  end

  def get_follow1(phrase, paragraphs, i)
    return '' if i + 1 == paragraphs.size
    paragraphs[i + 1]
  end

  def get_follow2(phrase, paragraphs, i)
    return '' if [i + 1, i + 2].include? paragraphs.size
    paragraphs[i + 2]
  end

  def get_sentence(phrase, paragraph)
    sentences = @m.tokenize_text(paragraph)
    sentences.each do |sentence|
      return sentence if phrase.in? sentence.downcase
    end

    # if no sentence is returned, return nil
    Rails.logger.error("sentence not found for #{phrase}, #{paragraph}")
    nil
  end
end
