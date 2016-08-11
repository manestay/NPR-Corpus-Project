require 'tactful_tokenizer'
require 'csv'

class SearchDatabase
  def initialize(tokenizer = nil, verbose: false)
    @verbose = verbose
    puts 'training tokenizer...'
    @m = tokenizer || TactfulTokenizer::Model.new
  end

  def search(phrase, transcripts = Transcript.all)
    hit_array = [{ phrase: phrase }]
    hits = 0
    transcripts.each do |transcript|
      paragraphs = transcript.paragraphs
      next unless paragraphs

      paragraphs.each_with_index do |paragraph, i|
        next unless phrase.in? paragraph.downcase
        hits += 1
        context = get_context(phrase, paragraphs, i)
        follow1 = get_follow1(phrase, paragraphs, i)
        follow2 = get_follow2(phrase, paragraphs, i)
        sentence = get_sentence(phrase, paragraph)
        hit = [
          hits,
          transcript.title,
          transcript.url_link,
          transcript.audio_link,
          context, paragraph, follow1,
          follow2,
          sentence
        ]

        hit_array << hit

        puts "#{hits}. #{transcript.title}\n#{sentence}" if @verbose
      end
    end
    puts "Found #{hits} hits in #{transcripts.count} files"
    hit_array
  end

  def generate_csv(hit_array, file_name: nil)
    phrase = hit_array.first[:phrase] rescue 'phrase'
    file_name ||= "results-#{phrase}.csv"
    CSV.open(file_name, "wb") do |csv|
      csv << [
        'Number',
        'Title',
        'Trans link',
        'Audio link',
        'Context',
        'Paragraph',
        'Continuation',
        'Continuation2',
        'Sentence'
      ]
      hit_array.each { |hit| csv << hit }
    end
  end

  private

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
      return sentence if phrase.in? sentence
    end
  end
end