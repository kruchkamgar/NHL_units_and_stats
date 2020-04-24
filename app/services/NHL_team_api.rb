=begin
fetches the teams' information
-

- does not fetch all the seasons (leave this to application logic / seeds.rb)
=end

module NhlTeamApi

  TEAM_URL = 'https://statsapi.web.nhl.com/api/v1/teams/'
  BASE_URL = 'https://statsapi.web.nhl.com/api/v1/teams/'
  SCHEDULE_URL = 'https://statsapi.web.nhl.com/api/v1/schedule'

# use extend if no reason to use instance/state
  # class << self; end;
  def create_all_teams_by_season
    create_teams
  end

  def create_teams
    teams_data =
    JSON.parse(RestClient.get(TEAM_URL))

    prepared_teams =
    teams_data["teams"]
    .map do |info_hash|
      Hash[
        team_id: info_hash["id"],
        name: info_hash["name"],
        season: @season,
        created_at: Time.now,
        updated_at: Time.now ]
    end
    teams_changes =
    SqlOperations.sql_insert_all("teams", prepared_teams ).count
    # grab teams
    if teams_changes > 0
      inserted_teams = Team.order(id: :desc).limit(teams_changes)
    end # performance: return prepared_teams as well?
  end

  class Adapter

  include NhlTeamApi
    def initialize (name: nil, team:, season: nil, start_date: nil, end_date: nil)
      @name, @team, @season, @start_date, @end_date = name, team, season, start_date, end_date

      set_season() unless @season # string
    end

    def find_or_create_team
      @team.name =
      (@name = get_team_name["teams"][0]["name"]) unless @team.name
      @team.save
      self
    end

    def fetch_data
      # get games from schedule
      sched_data = JSON.parse(RestClient.get(get_sched_url))
    end

  private

    # def get_roster_url
    #   "#{BASE_URL}#{@team_id}/roster"
    # end
    def get_team_name
      JSON.parse(RestClient.get(TEAM_URL+"#{@team.team_id}"))
    end

    def get_sched_url
      if @start_date == nil
        start_date = "#{@season[0, 4]}-09-01"
      else
        start_date = "#{@season[0, 4]}-#{@start_date}"
      end

      if @end_date == nil
        end_date = "#{@season[4, 4]}-07-01"
      else
        end_date = "#{@season[4, 4]}-#{@end_date}"
      end

      "#{SCHEDULE_URL}?teamId=#{@team.team_id}&startDate=#{start_date}&endDate=#{end_date}"
    end

  end
  # /////////////////////  helpers  ///////////////////// #

  def set_season(season = nil)
    if season then return (@season = season) end

    year = Date.current.year
    if Date.current.month > 9
      @season = "#{year}#{year+1}"
    else
      @season = "#{year-1}#{year}"
    end
  end

end # module
