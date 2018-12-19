
class UnitsController < ApplicationController

  def index
    Unit.first(10)

    render json: Unit.last(10).to_json(include: [:instances])
  end

  def show

  end

end
