

# redundant code with seeds.rb? or keep limited seed file to save time
# ... make into a library module


def create_events_sample
  single_team_events =
  @events_hashes
  .select do |event|
    event["teamId"] == 1 end

  sorted_events =
  single_team_events
  .group_by do |event|
    event["period"] end
    .each do |period, group|
    group.sort! do |a, b|
      a["startTime"] <=> b["startTime"] end
  end

  sorted_events
  .each do |period, group|
    group.each do |event|
      Event.find_or_create_by( event_type: event["eventDescription"] || "shift", duration: event["duration"], start_time: event["startTime"], end_time: event["endTime"], shift_number: event["shiftNumber"], period: event["period"], player_id_num: event["playerId"], game_id: 1 )
      #API lists null, except for goals
    end
  end
end

def sample_shifts_overlap
   [
    {"duration"=>"01:00", "endTime"=>"10:59",  "firstName"=>"Brian", "lastName"=>"Gibbons", "period"=>3, "playerId"=>8476207, "startTime"=>"09:59", "typeCode"=>517},
    {"duration"=>"00:45", "endTime"=>"10:35",  "firstName"=>"Bee", "lastName"=>"Johnson", "period"=>3, "playerId"=>2347890, "startTime"=>"09:50", "typeCode"=>517},
    {"duration"=>"01:10", "endTime"=>"11:20",  "firstName"=>"Brian", "lastName"=>"Boyle", "period"=>3, "playerId"=>1236789, "startTime"=>"10:10", "typeCode"=>517}
  ]
end

def sample_shifts_disparate
  [
   {"duration"=>"01:00", "endTime"=>"10:59",  "firstName"=>"Brian", "lastName"=>"Gibbons", "period"=>3, "playerId"=>8476207, "startTime"=>"09:59", "typeCode"=>517},
   {"duration"=>"00:45", "endTime"=>"09:59",  "firstName"=>"Bee", "lastName"=>"Johnson", "period"=>3, "playerId"=>2347890, "startTime"=>"09:14", "typeCode"=>517},
   {"duration"=>"01:10", "endTime"=>"11:20",  "firstName"=>"Brian", "lastName"=>"Boyle", "period"=>3, "playerId"=>1236789, "startTime"=>"10:10", "typeCode"=>517}
 ]
end

# [insert] comparisons btn input hash and activerecord
def events_with_db_keys (events)
  events.
  map do |event|
    Hash[
      event.keys.
      map do |key|
        if API.rassoc(key)
          [ API.rassoc(key).first,
            event[key]
          ]
        elsif Event.column_names.include? key
          event.assoc(key)
        end
      end.compact
    ]
  end
end
