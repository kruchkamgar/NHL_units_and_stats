
class UnitsController < ApplicationController

  def index
    @units = Unit.order(created_at: :desc).limit(3)

    render json: @units
    # Unit.order(created_at: :desc).limit(3).
    # to_json(
    #   include: [instances:
    #     { include: [:events] }
    # ] )
  end

  def show
    unit_id = unit_params[:id]

    unit = Unit.find(unit_id)
    render json: unit.to_json
  end

private
  def unit_params
    params.require(:unit).permit(:id)
  end

end
