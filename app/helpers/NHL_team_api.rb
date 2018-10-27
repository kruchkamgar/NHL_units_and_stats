=begin
fetches the teams' information
-
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
      Team.find_or_create_by(team_id: @team_id, season: @season)
      create_listed_roster

      fetch_data
    end

    def fetch_data
      # get games from schedule
      sched_data = JSON.parse(RestClient.get(get_sched_url))
      # call NHLGameAPI::Adapter.new().create_game for each scheduled game
      sched_data["dates"].each { |date_hash|
        game_id = date_hash["games"].first["gamePk"]
        NHLGameAPI::Adapter.new(game_id: game_id).create_game
        # byebug
      }

    end

    private

    def create_listed_roster
      # roster.find_or_create_by(...)
      # data = JSON.parse(RestClient.get(get_roster_url))
      # roster.team_id =
    end

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
