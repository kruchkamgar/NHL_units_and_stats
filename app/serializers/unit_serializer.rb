class UnitSerializer < ActiveModel::Serializer
  attributes :id, :created_at, :instances

  has_many :instances
  def instances
    Hash[
      players_names:
        self.object.instances.first.events.
        select do |event|
          event.event_type == "shift" end.
        map do |event|
          event.player_profiles.
          map do |profile|
            [ profile.player.first_name,
            profile.player.last_name ].
            join(' ') end
        end.flatten(1)
    ]
  end #instances


end
