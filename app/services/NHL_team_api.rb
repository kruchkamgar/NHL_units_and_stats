=begin
fetches the teams' information
-

- does not fetch all the seasons (leave this to application logic / seeds.rb)
=end

module NHLTeamAPI

  TEAM_URL = 'https://statsapi.web.nhl.com/api/v1/teams/'
  BASE_URL = 'https://statsapi.web.nhl.com/api/v1/teams/'
  SCHEDULE_URL = 'https://statsapi.web.nhl.com/api/v1/schedule'

  class Adapter

    def initialize (name: nil, team_id:, season: nil, start_date: nil, end_date: nil)
      @name, @team_id, @season, @start_date, @end_date = name, team_id, season, start_date, end_date
      @year = Date.current.year
      get_season unless @season # string
    end

    def create_team
      team = Team.find_or_create_by(
        team_id: @team_id,
        season: @season
      )
      team.name = @name ||= (@name = get_team_name["teams"][0]["name"])
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


    # /////////////////////  helpers  /////////////////////#
    def get_season
        if Date.current.month > 9
          @season = "#{@year}#{@year+1}"
        else
          @season = "#{@year-1}#{@year}"
        end
    end

  end
end
