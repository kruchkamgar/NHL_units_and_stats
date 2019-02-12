class UnitSerializer < ActiveModel::Serializer
  attributes :id, :created_at, :instances

  has_many :instances
  def instances
    Hash[
      players_names:
      self.object.instances.
      map do |instance|
        instance.events.
        map do |event|
          event.player_profiles.
          map do |profile|
            [ profile.player.first_name,
            profile.player.last_name ].
            join(' ') end
        end
      end ] # map instances
  end #instances


end
