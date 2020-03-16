class TeamsController < ApplicationController
include Standings

  def index
    # teams = Team.last(5)
    #
    # render json: teams.to_json
    render json: Hash[
      power_scores: weighted_standings(),
      schedule: get_schedule_data() ]
  end

  def show
    team_id = team_params[:id]

    team = team.find(team_id)
    render json: team.to_json
  end
end
