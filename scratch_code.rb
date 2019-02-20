
@frame_event = event
basis =
Hash[
  start_time: event.start_time,
  end_time: event.end_time,
  event: event
]

form_instance =
Proc.new do |start, end, events|
  Hash[
    start_time: start,
    end_time: end,
    events: events ]

overlap_test( basis, overlaps[0] )


def overlap_test( basis, comparison, frame_st=nil, frame_et=nil )

  event_queue =
  Proc.new do |basis, b_start, comp|
    basis =
    Hash[
      start_time: b_start,
      event: basis ]
    comparison =
    Hash[
      start_time: comp.start_time,
      end_time: comp.end_time,
      event: comp ]
    [basis, comparison]
  end

  # basis = events[n]; comparison = events[n+1]
  n = events.index(basis[:event])

  min_by_et = Proc.new { @overlaps.min_by(&:end_time) }

  if basis[:start_time] == comparison[:start_time]
    # basis =
    # Hash[
    #   start_time: events[n].start_time,
    #   event: events[n] ]
    event_queue[events[n], events[n].start_time, events[n+1]]
    overlap_test( basis, comparison, min_by_et )
  elsif basis[:start_time] < comparison[:start_time] &&
    comparison[:start_time] < frame_et
    basis =
    Hash[
      start_time: comparison[:start_time],
      end_time: comparison[:end_time],
      event: comparison ]
    comparison =
    Hash[
      start_time: events[n+2].start_time,
      end_time: events[n+2].end_time,
      event: events[n+2] ]
    # ** return / call proc?
    # n becomes– next n, @start time: comparison start time [which becomes n]--
    overlap_test( basis, comparison, min_by_et ) # if n+2
     # if frame_et< "20:00"
  elsif min_by_et.end_time <= comparison[:start_time]
    @overlaps.delete_at( index(min_by_et.call()) )
    # ** return / call proc - frame_st, frame_et
    # n becomes– initial basis, @start time: min_by end time--
    basis =
    Hash[
      start_time: min_by_et.start_time,
      end_time: @frame_event.end_time,
      event: @frame_event ]
    n = events.index(@frame_event)
    comparison =
    Hash[
      start_time: events[n+1].start_time,
      end_time: events[n+1].end_time,
      event: events[n+1] ]
    overlap_test(basis, comparison, min_by_et.call())
  elsif basis[:start_time] < comparison[:end_time]
    comparison =
    Hash[
      start_time: basis[:start_time],
      end_time: events[n+1].end_time,
      event: events[n+1] ]
    overlap_test(basis, comparison, min_by_et.call())
  else
    # ** return / call proc? //no more overlapping shifts
    @overlaps.delete_at( index(min_by_et.call()) )
    # //n becomes– initial basis, @start time: comparison end time--
    basis =
    Hash[
      start_time: comparison[:end_time],
      end_time: @frame_event.end_time,
      event: @frame_event ]
    n = events.index(@frame_event)
    comparison =
    Hash[
      start_time: events[n+1].start_time,
      end_time: events[n+1].end_time,
      event: events[n+1] ]
    overlap_test(basis, comparison, min_by_et.call()) #(if < "20:00")
  end

end
