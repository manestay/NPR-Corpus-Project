require 'tactful_tokenizer'
require 'csv'

class SearchDatabase
  def initialize(tokenizer = nil, verbose: false)
    @verbose = verbose
    @m = tokenizer || TactfulTokenizer::Model.new
    puts 'training tokenizer...' unless tokenizer
  end

  def search(phrase, transcripts: Transcript.all, limit: nil, whole_word: false)
    hit_array = [{ phrase: phrase }] # save phrase in array
    transcripts.each do |transcript|
      paragraphs = transcript.paragraphs
      next unless paragraphs # if no paragraphs

      paragraphs.each_with_index do |paragraph, i|
        next unless paragraph # if blank paragraph
        next unless phrase.in? paragraph.downcase.split(/[^\w']+/) # if phrase not found

        hit_info = get_hit_info(phrase, paragraph, paragraphs, i)

        # do not write if there was an error
        if hit_info.include? nil
          Rails.logger.error("#search error: story_id #{transcript.id} " \
          "paragraph ##{i}, phrase #{phrase}")
          next
        end

        hit = Result.new(
          title: transcript.title,
          url_link: transcript.url_link,
          audio_link: transcript.audio_link,
          context: hit_info[0],
          paragraph: hit_info[1],
          follow1: hit_info[2],
          follow2: hit_info[3],
          sentence: hit_info[4]
        )

        hit_array << hit

        puts "#{hit_array.size - 1}. #{transcript.title}
        #{sentence}" if @verbose

        return hit_array if limit && hit_array.size - 1 == limit
      end
    end
    hit_array
  end

  private

  # return context, follow1, follow2, sentence in an array
  def get_hit_info(phrase, paragraph, paragraphs, i)
    context = get_context(phrase, paragraphs, i)
    follow1 = get_follow1(phrase, paragraphs, i)
    follow2 = get_follow2(phrase, paragraphs, i)
    sentence = get_sentence(phrase, paragraph)
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
