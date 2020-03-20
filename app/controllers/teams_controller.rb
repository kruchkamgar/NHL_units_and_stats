class TeamsController < ApplicationController
include Standings

  def index
    # teams = Team.last(5)
    #
    # render json: teams.to_json
  end

  def show
    # team_id = team_params[:id]
    #
    # team = team.find(team_id)
    # render json: team.to_json
    range = games_params[:range].to_i

    render json: Hash[
      powerScores: weighted_standings(range),
      schedule: get_schedule_data(Standings::DATE_NOW) ]
  end

private

  def games_params
    params.permit(:range)
  end

end
