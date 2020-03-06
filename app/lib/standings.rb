
module Standings

  WINS_POINTS = 2
  # LOSSES_POINTS = 0
  # OT_POINTS = 1

  def weighted_standings(end_date=(Time.now.strftime "%Y-%m-%d"))
    game_results = latest_game_results(end_date)
    recency_multiplier = 2

    weighted_standings =
    game_results
    .map do |name, games|
      if games.count < 20
        return [ name, reduce_results(games[-1]) ]
      else
        latest = 20
        points_last_20 = calc_points_last_(games, latest)
        points_prior = reduce_results(games[-1]) - points_last_20

        recency_weight = latest/games.count * recency_multiplier

        power_score =
        recency_weight * points_last_20 +
        (1 - recency_weight) * points_prior

        return [ name, power_score ]
      end
    end
    .sort do |a, b|
      a[1] <=> b[1] end

  end

  def calc_points_last_(games_results, last)
    bound = -(last+1)

    latest_n_record =
    Hash[
      wins: game_results[-1]['wins'] - games_results[bound]['wins'],
      losses: game_results[-1]['losses'] - games_results[bound]['losses'],
      ot: game_results[-1]['ot'] - games_results[bound]['ot']
    ]

    reduce_results(latest_n_record)
  end

  def reduce_results(record)
    record
    .reduce do |total, results_by_type|
      case results_by_type.keys[0]
      when :wins
        total += results_by_type[:wins] * WINS_POINTS
      when :losses
        total
      when :ot
        total += results_by_type[:ot]
      end
    end

  end #reduce_results

  def latest_game_results(end_date)
    # query the NHL schedule for last 20 games
    # find the last n games for each team:
    # - https://statsapi.web.nhl.com/api/v1/schedule?startDate=2019-02-10&endDate=2020-01-01

    # push to array within hash of team.
    # compare record update to previous game, and add hash marking w/l/ot for current game in array
    cached = Rails.cache.read(end_date)
    return cached if cached

    records = Hash[]

    # add a result for each teams' games, within records (by team)
    get_schedule_data(end_date)['dates']
    .each do |date|
      date['games']
      .each do |game|
        next if game['gameType'] != "R"
        away = game['teams']['away']['team']['name']
        home = game['teams']['home']['team']['name']
        records[away] ||= []; records[home] ||= []


        record_away = game['teams']['away']['leagueRecord']
        record_home = game['teams']['home']['leagueRecord']
        # add games to array for team games
        records[away] << record_away; records[home] << record_home

        # add hash key :result to record whether a win or loss or ot loss
        if records[away].count > 1
          if records[away][-2]['wins'] < records[away][-1]['wins']
            records[away][-1][:result] = 2
          elsif records[away][-2]['losses'] < records[away][-1]['losses']
            records[away][-1][:result] = 0
          else
            # byebug if !records[away][-2]['ot'] || !records[away][-1]['ot']
            if records[away][-2]['ot'] < records[away][-1]['ot']
            records[away][-1][:result] = 1 end
          end
        end
        if records[home].count > 1
          if records[home][-2]['wins'] < records[home][-1]['wins']
            records[home][-1][:result] = 2
          elsif records[home][-2]['losses'] < records[home][-1]['losses']
            records[home][-1][:result] = 0
          elsif records[home][-2]['ot'] < records[home][-1]['ot']
            records[home][-1][:result] = 1
          end
        end

      end #each
    end #map

    Rails.cache.write(end_date, records, expires_in: 24.hours)
    return records
  end

  def get_schedule_data(end_date)
    JSON.parse( RestClient.get(schedule_url(end_date: end_date)) )
  end

  def schedule_url(
    start_date: "2019-10-01", end_date: end_date )
    "https://statsapi.web.nhl.com/api/v1/schedule?startDate=#{start_date}&endDate=#{end_date}"
  end

  def get_standings_last_ten
    'https://statsapi.web.nhl.com/api/v1/standings?expand=standings.record'
  end

  def get_standings_data(dates)
    'https://api.nhle.com/stats/rest/en/team/summary?isAggregate=true&isGame=true&sort=%5B%7B%22property%22:%22points%22,%22direction%22:%22DESC%22%7D,%7B%22property%22:%22wins%22,%22direction%22:%22DESC%22%7D%5D&start=0&limit=50&factCayenneExp=gamesPlayed%3E=1&cayenneExp=gameDate%3C=%222020-02-04%2023%3A59%3A59%22%20and%20gameDate%3E=%222019-10-02%22%20and%20gameTypeId=2'
  end

end
