class Admin::AreasController < ApplicationController
  before_action :set_area, only: [:show, :edit, :update, :destroy]

  def index
    @areas = Area.all.order("name")
  end

  def show
  end

  def new
    @area = Area.new
  end

  def create
    @area = Area.new(area_params)
    
    if params[:area][:geojson_url].present?
      @area.geom = Area.from_geojson_url(params[:area][:geojson_url])
    end

    if @area.save
      redirect_to admin_areas_path, notice: 'Area was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if params[:area][:geojson_url].present?
      @area.geom = Area.from_geojson_url(params[:area][:geojson_url])
    end

    if @area.update(area_params.except(:geojson_url))
      redirect_to admin_areas_path, notice: 'Area was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @area.destroy
    redirect_to admin_areas_path, notice: 'Area was successfully destroyed.'
  end

  private

  def set_area
    @area = Area.find(params[:id])
  end

  def area_params
    params.require(:area).permit(:name, :code)
  end
end 