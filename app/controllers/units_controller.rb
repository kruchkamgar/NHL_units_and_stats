
class UnitsController < ApplicationController

  def index
    
    render json: Unit.last(10).to_json(include: [:instances])
  end

  def show

  end

end
