class SearchesController < ApplicationController
  before_action :set_search, only: [:show, :update, :destroy, :download]
  include SearchesHelper

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

    redirect_to search_path(id: @search.id)
  end

  def show
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
    phrase = @search.phrase
    time = @search.submitted_at
    file_location = generate_csv(@search.results, phrase, time)
    send_file(file_location, type: 'text/csv', disposition: 'attachment')
  end

  def destroy
    @search.results.destroy_all
    @search.destroy
    respond_to do |format|
      format.html { redirect_to history_path, notice: 'Search was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def set_search
    @search = Search.find(params[:id])
  end

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
