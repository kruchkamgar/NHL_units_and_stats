require 'byebug'

class TeamsController < ApplicationController
include Standings

  def index
    # teams = Team.last(5)
    #
    # render json: teams.to_json
  end

  def powerScores
    range = games_params[:range].to_i
    if games_params[:date]
      date = games_params[:date]
    else
      date = Standings::DATE_NOW end

    render json: Hash[
      powerScores: weighted_standings(
        range, date),
      schedule: get_schedule_data(date) ]
  end

private

  def games_params
    params.permit(:range, :date)
  end

end
