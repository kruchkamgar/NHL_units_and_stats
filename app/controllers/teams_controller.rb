class TeamsController < ApplicationController
include Standings

  def index
    # teams = Team.last(5)
    #
    # render json: teams.to_json
    render json: weighted_standings().to_json
  end

  def show
    team_id = team_params[:id]

    team = team.find(team_id)
    render json: team.to_json
  end
end
