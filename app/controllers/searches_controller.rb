class SearchesController < ApplicationController
  include SearchHelper

  def index
    return unless current_user
    @searches = current_user.searches
  end

  def new
    @search = Search.new
  end

  def create
    @search = Search.new(search_params)

    current_user.searches << @search if current_user

    searcher = SearchDatabase.new
    @transcripts = Transcript.order_by(:date.desc).where(
      :date.gte => @search.start_date,
      :date.lte => @search.end_date
    )
    @hits = searcher.search(
      @search.phrase,
      transcripts: @transcripts,
      limit: @search.limit
    ).drop(1) # drop data on phrase

    save_search(@transcripts.count)

    redirect_to search_path id: @search.id
  end

  def show
    @search = Search.where(id: params[:id]).first
    return unless @search
    @results =
      if @search.results.count <= 50
        @search.results
      else
        @limited = true
        @search.results.limit(50)
      end
  end

  def download
    search = Search.where(id: params[:id]).first
    phrase = search.phrase
    time = search.submitted_at
    file_location = generate_csv(search.results, phrase, time)
    send_file(file_location, target: '_blank', type: 'text/csv', disposition: 'attachment')
  end

  private

  def save_search(transcript_count)
    @search.update_attribute(:transcript_count, transcript_count)
    @hits.each do |hit|
      @search.results << hit
      hit.save
    end
    @search.save
  end

  def search_params
    params.require(:search).permit(
      :phrase,
      :limit,
      :start_date,
      :end_date,
      :submitted_at
    )
  end
end
