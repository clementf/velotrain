class Admin::Gpx::TracksController < ApplicationController
  include Pagy::Backend
  
  before_action :set_gpx_track, only: %i[show edit update destroy]

  # GET /gpx/tracks or /gpx/tracks.json
  def index
    @pagy, @gpx_tracks = pagy(Gpx::Track.all.order(created_at: :desc), items: 20)
  end

  # GET /gpx/tracks/1 or /gpx/tracks/1.json
  def show
  end

  # GET /gpx/tracks/new
  def new
    @gpx_track = Gpx::Track.new
  end

  # GET /gpx/tracks/1/edit
  def edit
  end

  # POST /gpx/tracks or /gpx/tracks.json
  def create
    @gpx_track = Gpx::Track.new(gpx_track_params)

    respond_to do |format|
      if @gpx_track.save
        format.html { redirect_to admin_gpx_tracks_url(@gpx_track), notice: "Track was successfully created." }
        format.json { render :show, status: :created, location: @gpx_track }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @gpx_track.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /gpx/tracks/1 or /gpx/tracks/1.json
  def update
    respond_to do |format|
      if @gpx_track.update(gpx_track_params)
        format.html { redirect_to admin_gpx_tracks_url(@gpx_track), notice: "Track was successfully updated." }
        format.json { render :show, status: :ok, location: @gpx_track }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @gpx_track.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /gpx/tracks/1 or /gpx/tracks/1.json
  def destroy
    @gpx_track.destroy!

    respond_to do |format|
      format.html { redirect_to admin_gpx_tracks_url, notice: "Track was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_gpx_track
    @gpx_track = Gpx::Track.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def gpx_track_params
    params.require(:gpx_track).permit(:name, :file, :visible)
  end
end
