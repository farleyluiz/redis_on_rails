class Attendee < ActiveRecord::Base
  include Followings

  has_many :authentications

  is_gravtastic! filetype: :jpg, size: 80

  def conferences
    #Conference.find_all_by_id(rdb[:conference_ids]) # gotcha, didn't call smembers
    Conference.find_all_by_id(rdb[:conference_ids].smembers)
  end

  def events(other=nil)
    if other
      # make an INTERSECTION of all events that are shared between you and the conference
      rdb.redis.zinterstore(rdb[:events][other], [rdb[:events], other.rdb[:events]], aggregate: "min")
      # Note that zrange and zrevrange are not score based.. they're 0-index
      # Event.where(id: rdb[:events][other].zrange(0, Time.now.to_i))
      Event.where(id: rdb[:events][other].zrange(0, -1))
    else
      Event.where(id: rdb[:events].zrange(0, -1))
    end
  end

  def name
    # won't work with mass-assignment
    rdb[:name].get
  end

  def name=(n)
    # won't work with mass-assignment
    rdb[:name].set n
  end

  def registered_for?(conference)
    conference.registered?(self)
  end

  def register_for(conference)
    conference.register(self)
  end

  def unregister_from(conference)
    conference.unregister(self)
  end

  def self.null
    Attendee.new
  end
end
