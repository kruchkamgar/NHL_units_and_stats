=begin
fetches the teams' information
-

- does not fetch all the seasons (leave this to application logic / seeds.rb)
=end

module NHLTeamAPI

  TEAM_URL = 'https://statsapi.web.nhl.com/api/v1/teams/'
  BASE_URL = 'https://statsapi.web.nhl.com/api/v1/teams/'
  SCHEDULE_URL = 'https://statsapi.web.nhl.com/api/v1/schedule'

  def create_all_teams_by_season
    # get_season
    make_teams_data
  end

  def make_teams_data
    teams_data =
    JSON.parse(RestClient.get(TEAM_URL))

    made_teams_array =
    teams_data["teams"].
    map do |info_hash|
      Hash[
        team_id: info_hash["id"],
        name: info_hash["name"],
        season: @season,
        created_at: Time.now, updated_at: Time.now ]
    end
    teams_changes =
    SQLOperations.sql_insert_all("teams", made_teams_array )
    # grab teams
    if teams_changes > 0
      inserted_teams = Team.order(id: :desc).limit(teams_changes)
    end
  end

  class Adapter

    def initialize (name: nil, team_id:, season: nil, start_date: nil, end_date: nil)
      @name, @team_id, @season, @start_date, @end_date = name, team_id, season, start_date, end_date

      get_season unless @season # string
    end

    def create_team
      team =
      Team.find_or_create_by(
        team_id: @team_id,
        season: @season
      )

      team.name = @name ||=
      (@name = get_team_name["teams"][0]["name"])
      team.save
      [team, self]
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
      JSON.parse(RestClient.get(TEAM_URL+"#{@team_id}"))
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

      "#{SCHEDULE_URL}?teamId=#{@team_id}&startDate=#{start_date}&endDate=#{end_date}"
    end


    # /////////////////////  helpers  ///////////////////// #
  end

  def get_season
    year = Date.current.year
    if Date.current.month > 9
      @season = "#{year}#{year+1}"
    else
      @season = "#{year-1}#{year}"
    end
  end
end