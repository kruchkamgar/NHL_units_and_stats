
module PowerScores

  COUNT_LATEST = 20
  MULTIPLIER = 2
  DATE_NOW = Time.now.strftime "%Y-%m-%d"
  WINS_POINTS = 2
  # LOSSES_POINTS = 0
  # OT_POINTS = 1

  def power_scores_by_days(
    days=1,
    end_date=DATE_NOW,
    count_latest=COUNT_LATEST,
    recency_multiplier=MULTIPLIER
  )

  records_by_team = game_results_by_team(end_date)[:records] # team name => array of records hashes

  # create a hash by date, by iterating over the schedule
  # - (contingency: powerScore from equal number of games)-- find the min number of games played, and put a corresponding lower bounds on sample for calculation of
    game_results_by_team(end_date)[:schedule][-days..-1]
    .map do |date_hash|
      # - for each date in schedule, find the teams playing games
      date = date_hash.keys[0]
      games = date_hash[date]

      team_names =
      games
      .map do |game|
        game["teams"]
        .map do |side, hash|
          hash['team']['name'] end
      end.flatten
      # per team, find index of game by date

      # source power_scores for each team_name:
      # - by mapping team_names, to team records ('records_by_team': arrays of game results per game date)
      power_scores_by_team =
      team_names
      .map do |name|
        game_records = records_by_team[name].reverse
        head = game_records.index do |record|
          record[:date] == date end

        if game_records.size <= count_latest
          points_latest_n = tally_points( game_records[tail] )
        else
          tail = (count_latest+head+1)
          points_latest_n =
          tally_points( game_records[head] ) - tally_points( game_records[tail] )

          count_prior = game_records[tail..-1].size
          # - calculate powerScore (which implicitly corresponds to the date)
          # points_latest, count_prior, games = results_range

          power_score =
          calc_power_score(
            count_latest, recency_multiplier, points_latest_n,
            count_prior, game_records, head )

          Hash[ team: name, powerScore: power_score] end #else
      end # map team_names
      Hash[ date: date, powerScores: power_scores_by_team ]

    end #map

  end

  # should break at calc_power_score, needs to work for this and power_scores_by_days
  def weighted_standings(
    range=1,
    end_date=DATE_NOW,
    count_latest=COUNT_LATEST,
    recency_multiplier=MULTIPLIER
   )

    # use this by-team hash to calculate points between [count_latest] games
    game_results_by_team = game_results_by_team(end_date)

    # latest points, over last (range) games per team
    latest_points_and_count_by_team_over_range =
    game_results_by_team[:records]
    .map do |name, games|
      head = games.count - count_latest

      if head <= range then effective_range = head # put a floor on the effective_range
      else effective_range = range end

      # if games.count < count_latest
      if effective_range < 1
        Hash[
          name: name,
          points_and_count: tally_points(games[-1]) ]
      else
        results_range_data =
        Array.new(effective_range)
        .map.with_index do |slot, index|
          head_tracking = -(count_latest+index+1)
          tail = -(1+index)
          points_latest_n =
          tally_points( games[tail] ) -
          tally_points( games[head_tracking] )
          # results within array of ranged (by count_latest) games
          Array.new([
            points_latest_n,
            head - index, # count_prior
            games ])
        end # results_range
        Hash[
          name: name,
          points_and_count: results_range_data ]
      end
    end #map latest_points_and_count_by_team_over_range

    weighted_standings_over_range =
    latest_points_and_count_by_team_over_range
    .map do |team_hash|
      results_range_data = team_hash[:points_and_count]
      name = team_hash[:name]

      if results_range_data.class != Array
        [ name, results_range_data ]
      else
        # map through range of games
        power_scores_over_range =
        results_range_data
        .map.with_index do |results_range, index|
          # points_latest, count_prior, games = results_range

          calc_power_score(
            count_latest, recency_multiplier,
            *results_range)

          head = -(count_latest + index + 1)
          tail = -(1+index)
          # increase (decrease) the 'share' represented by latest games by a multiplier

          Hash[
            powerScore: power_score_to_points.round(1),
            pointsPercentageLatest: points_latest_percentage.round(3),
            pointsPercentagePrior: points_prior_percentage.round(3),
            asOfDate: games[tail][:date] ]
        end

        # byebug
        Hash[
          name: name,
          scores: power_scores_over_range ]
      end #if
    end #map weighted_standings_over_range

    # hash, or array, depending on count_latest > games played overall
    if weighted_standings_over_range[0].class == Hash
      weighted_standings_over_range
      .sort_by do |team_hash|
        team_hash[:scores]
        .first[:powerScore] end.reverse
    elsif
      weighted_standings_over_range[0].class == Array
      weighted_standings_over_range
      .sort do |a, b| a[1] <=> b[1] end
    end
  end

  def calc_power_score(
    count_latest, recency_multiplier, points_latest, count_prior, games, head= 0 )

    adjusted_count_latest =
    count_latest * recency_multiplier

    count_prior_delta =
    adjusted_count_latest - count_latest
    adjusted_count_prior =
    count_prior - count_prior_delta
    # head_result = head_results_last_(games, count_latest)

    # points_latest = tally_points(tally_latest)
    points_prior = tally_points(games[head]) - points_latest

    points_latest_percentage =
    points_latest/(count_latest * WINS_POINTS).to_f
    points_prior_percentage =
    points_prior/(count_prior * WINS_POINTS).to_f

    power_score =
    points_prior_percentage * adjusted_count_prior +
    points_latest_percentage * adjusted_count_latest
    # recency_multiplier * points_last_ +
    # points_prior * contraction_weight

    power_score_to_points = power_score * WINS_POINTS.to_f

    return Hash[
      powerScore: power_score_to_points.round(1),
      pointsPercentageLatest: points_latest_percentage.round(3),
      pointsPercentagePrior: points_prior_percentage.round(3),
      asOfDate: games[head][:date] ]
      # .match( /.+(?=T)/)[0]
  end

  # convert record to points
  def tally_points(record)
    points =
    record
    .inject(0) do |total, results_by_type|
      case results_by_type[0]
      when :wins, "wins"
        total +
        (results_by_type[1] * WINS_POINTS)
      # when :losses, "losses"
      #   total
      when :ot, "ot"
        total + results_by_type[1]
      else total
      end
    end
  end #tally_points

  def game_results_by_team(end_date)
    # query the NHL schedule for last 20 games
    # find the last n games for each team:
    # - https://statsapi.web.nhl.com/api/v1/schedule?startDate=2019-02-10&endDate=2020-01-01

    # push to array within hash of team.
    # compare record update to previous game, and add hash marking w/l/ot for current game in array

# syntax: use Rails.cache.fetch?
    cached = Rails.cache.read(end_date)
    return cached if cached

    records = Hash[]
    games = []

    # add a result for each teams' games, within records (by team)
    get_schedule_data(end_date)['dates']
    .each do |date|
      games.push(
        Hash[
          date['date'] => date['games'] ])

      date['games']
      .each do |game|
        next if game['gameType'] != "R"
        away = game['teams']['away']['team']['name']
        home = game['teams']['home']['team']['name']
        records[away] ||= []; records[home] ||= []

        record_away = game['teams']['away']['leagueRecord']
        .merge(date: date['date'])
        record_home = game['teams']['home']['leagueRecord']
        .merge(date: date['date'])
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

    records_and_games = Hash[ records: records, schedule: games ]
    Rails.cache.write(end_date, records_and_games, expires_in: 24.hours)
    return records_and_games
  end

  # def schedule_by_date(end_date)
  #   get_schedule_data(end_date)
  #   # .map do
  # end

  def get_schedule_data(end_date)
    Rails.cache.fetch("schedule/#{end_date}", expires_in: 24.hours) do
      JSON.parse(
        RestClient.get( schedule_url(end_date: end_date) ))
    end
  end

  def schedule_url(
    start_date: "2019-10-01", end_date: )
    "https://statsapi.web.nhl.com/api/v1/schedule?startDate=#{start_date}&endDate=#{end_date}"
  end

  def get_standings_last_ten
    'https://statsapi.web.nhl.com/api/v1/standings?expand=standings.record'
  end

  def get_standings_data(dates)
    'https://api.nhle.com/stats/rest/en/team/summary?isAggregate=true&isGame=true&sort=%5B%7B%22property%22:%22points%22,%22direction%22:%22DESC%22%7D,%7B%22property%22:%22wins%22,%22direction%22:%22DESC%22%7D%5D&start=0&limit=50&factCayenneExp=gamesPlayed%3E=1&cayenneExp=gameDate%3C=%222020-02-04%2023%3A59%3A59%22%20and%20gameDate%3E=%222019-10-02%22%20and%20gameTypeId=2'
  end

end
