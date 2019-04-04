
class UnitsController < ApplicationController

include QueryDerivedUnits
  def index
    # @units = Unit.order(updated_at: :desc).limit(3)
    # @units = Unit.joins(:tallies).order("tallies.plus_minus + 0 DESC").limit(5)
    #
    # render json: @units

    @derived_units =
    display_units("Forward", team_id: 1, position_type_mark: 3)

    render json: @derived_units.as_json
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
