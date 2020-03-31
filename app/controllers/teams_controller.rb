require 'byebug'

class TeamsController < ApplicationController
include PowerScores

  def index
    # teams = Team.last(5)
    #
    # render json: teams.to_json
  end

  def powerScores
    days = games_params[:days].to_i
    if games_params[:date]
      date = games_params[:date]
    else
      date = PowerScores::DATE_NOW end

    render json: Hash[
      powerScores: power_scores_by_days(
        days, date),
      schedule: get_schedule_data(date) ]
  end

private

  def games_params
    params.permit(:days, :date)
  end

end
