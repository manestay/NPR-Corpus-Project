class TranscriptsController < ApplicationController
  include TranscriptsHelper
  before_action :set_transcript,
                only: [:show, :edit, :update, :destroy, :download]

  # GET /transcripts
  # GET /transcripts.json
  def index
    render file: 'public/404.html',
           status: :not_found,
           layout: false unless current_user
    @transcripts = Transcript.order_by(:date.desc).page(params[:page])
  end

  # GET /transcripts/1
  # GET /transcripts/1.json
  def show
  end

  # GET /transcripts/new
  def new
    @transcript = Transcript.new
  end

  # GET /transcripts/1/edit
  def edit
  end

  # POST /transcripts
  # POST /transcripts.json
  def create
    @transcript = Transcript.new(transcript_params)

    respond_to do |format|
      if @transcript.save
        format.html do
          redirect_to @transcript, notice: 'Transcript was successfully created.'
        end
        format.json { render :show, status: :created, location: @transcript }
      else
        format.html { render :new }
        format.json do
          render json: @transcript.errors, status: :unprocessable_entity
        end
      end
    end
  end

  # PATCH/PUT /transcripts/1
  # PATCH/PUT /transcripts/1.json
  def update
    respond_to do |format|
      if @transcript.update(transcript_params)
        format.html do
          redirect_to @transcript, notice: 'Transcript was successfully updated.'
        end
        format.json { render :show, status: :ok, location: @transcript }
      else
        format.html { render :edit }
        format.json do
          render json: @transcript.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def download
    data = generate_xml(@transcript)
    send_data(
      data,
      filename: "#{@transcript.title}.csv",
      type: 'text/xml',
      disposition: 'inline'
    )
  end

  # DELETE /transcripts/1
  # DELETE /transcripts/1.json
  def destroy
    @transcript.destroy
    respond_to do |format|
      format.html do
        redirect_to transcripts_url, notice: 'Transcript was successfully destroyed.'
      end
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_transcript
    @transcript = Transcript.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def transcript_params
    params.require(:transcript)
          .permit(:title, :date, :story_link, :audio_link, :text)
  end
end
