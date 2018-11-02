=begin
fetches the teams' information
-

- does not fetch all the seasons (leave this to application logic / seeds.rb)
=end

module NHLTeamAPI

  class Adapter

    BASE_URL = 'https://statsapi.web.nhl.com/api/v1/teams/'
    SCHEDULE_URL = 'https://statsapi.web.nhl.com/api/v1/schedule'

    def initialize (name: nil, team_id:, year: Date.current.year, season: nil, start_date: nil, end_date: nil)
      @name, @team_id, @year, @season, @start_date, @end_date = name, team_id, year, season, start_date, end_date
      get_season unless @season
    end

    def create_team
      team = Team.find_or_create_by(
        team_id: @team_id,
        season: @season,
        name: @name
      )
      team.name = @name
      team.save
      team
    end

    def fetch_data
      # get games from schedule
      sched_data = JSON.parse(RestClient.get(get_sched_url))
    end

    private

    def get_roster_url
      "#{BASE_URL}#{@team_id}/roster"
    end

    def get_sched_url
      if @start_date || @end_date  == nil
          @start_date = "#{@year-1}-09-01"
          @end_date = "#{@year}-07-01"
      end

      "#{SCHEDULE_URL}?teamId=#{@team_id}&startDate=#{@start_date}&endDate=#{@end_date}"
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
