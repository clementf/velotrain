class Admin::RegionalBikeRulesController < ApplicationController
  before_action :set_regional_bike_rule, only: [:edit, :update, :destroy]

  def index
    @regional_bike_rules = RegionalBikeRule.includes(:area).all
  end

  def new
    @regional_bike_rule = RegionalBikeRule.new
  end

  def create
    @regional_bike_rule = RegionalBikeRule.new(regional_bike_rule_params)

    if @regional_bike_rule.save
      redirect_to admin_regional_bike_rules_path, notice: 'Regional bike rule was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @regional_bike_rule.update(regional_bike_rule_params)
      redirect_to admin_regional_bike_rules_path, notice: 'Regional bike rule was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @regional_bike_rule.destroy
    redirect_to admin_regional_bike_rules_path, notice: 'Regional bike rule was successfully deleted.'
  end

  private

  def set_regional_bike_rule
    @regional_bike_rule = RegionalBikeRule.find(params[:id])
  end

  def regional_bike_rule_params
    params.require(:regional_bike_rule).permit(:area_id, :source_url, :bike_always_allowed_without_booking, :extracted_information, :network_code)
  end
end
