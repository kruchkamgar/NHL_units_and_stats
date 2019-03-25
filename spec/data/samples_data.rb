
module SamplesData

  def instances_stats_data
    [
      # EVG
      {goals: 2, assists: 4},
      {goals: 1, assists: 0},
      {goals: 0, assists: 0},

      # SHG
      {goals: 0, ppga: 0, shg:1, assists: 2},

      # PPGA, SHG
      {goals: 1, ppga: 1, shg:1, assists: 1},
      {goals: 0, ppga: 1, shg:0, assists: 0},

      #SHGA
      {goals: 1, ppga: 0, ppg:1, shga:1, assists: 1},
      {goals: 0, ppga: 0, ppg:0, shga:1, assists: 0},
      {goals: 0, ppga: 0, ppg:0, shga:0, assists: 0},

      # PPG
      {goals: 1, ppg: 1, assists: 1},
      {goals: 1, ppg: 0, assists: 0},
      {goals: 0, ppg: 0, assists: 0}
    ]
  end


end
