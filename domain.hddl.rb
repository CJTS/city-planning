# Generated by Hype
require '/Users/cjts/Workspace/Doctorate/city-planning/HyperTensioN/Hypertension'

module Basic
  include Hypertension
  extend self

  #-----------------------------------------------
  # Domain
  #-----------------------------------------------

  @domain = {
    # Operators
    :pickup => true,
    :drop => true,
    :move => true,
    :move_scout => true,
    :visit_scout => true,
    :move_attacker => true,
    :map => true,
    :map_enemy => true,
    :kill => true,
    # Methods
    :grow => [
      :grow_find_gather,
      :grow_find_gather_attacker
    ],
    :collect => [
      :collect_collect
    ],
    :find => [
      :find_find_not_enemy,
      :find_find_enemy
    ],
    :attack => [
      :attack_attack
    ],
    :visit => [
      :visit_visit
    ]
  }

  #-----------------------------------------------
  # Operators
  #-----------------------------------------------

  def pickup(_gatherer, _resource)
    return unless GATHERER.include?(_gatherer)
    return unless RESOURCE.include?(_resource)
    return unless @state[EMPTY].include?(_gatherer)
    return if @state[HAVE].include?([_gatherer, _resource])
    @state = @state.dup
    (@state[EMPTY] = @state[EMPTY].dup).delete(_gatherer)
    (@state[HAVE] = @state[HAVE].dup).unshift([_gatherer, _resource])
    true
  end

  def drop(_gatherer, _resource)
    return unless GATHERER.include?(_gatherer)
    return unless RESOURCE.include?(_resource)
    return unless @state[HAVE].include?([_gatherer, _resource])
    return if @state[EMPTY].include?(_gatherer)
    @state = @state.dup
    (@state[HAVE] = @state[HAVE].dup).delete([_gatherer, _resource])
    (@state[EMPTY] = @state[EMPTY].dup).unshift(_gatherer)
    true
  end

  def move(_gatherer, _from, _to)
    return unless GATHERER.include?(_gatherer)
    return unless LOCATION.include?(_from)
    return unless LOCATION.include?(_to)
    return unless @state[ON].include?([_gatherer, _from])
    return if @state[ON].include?([_gatherer, _to])
    @state = @state.dup
    (@state[ON] = @state[ON].dup).delete([_gatherer, _from])
    @state[ON].unshift([_gatherer, _to])
    true
  end

  def move_scout(_scout, _from, _to)
    return unless SCOUT.include?(_scout)
    return unless LOCATION.include?(_from)
    return unless LOCATION.include?(_to)
    return unless @state[ON].include?([_scout, _from])
    return if @state[ON].include?([_scout, _to])
    @state = @state.dup
    (@state[ON] = @state[ON].dup).delete([_scout, _from])
    @state[ON].unshift([_scout, _to])
    true
  end

  def visit_scout(_scout, _from, _to)
    return unless SCOUT.include?(_scout)
    return unless LOCATION.include?(_from)
    return unless LOCATION.include?(_to)
    return unless @state[ON].include?([_scout, _from])
    return if @state[ON].include?([_scout, _to])
    @state = @state.dup
    (@state[ON] = @state[ON].dup).delete([_scout, _from])
    @state[ON].unshift([_scout, _to])
    (@state[VISITED] = @state[VISITED].dup).unshift(_to)
    true
  end

  def move_attacker(_attacker, _from, _to)
    return unless ATTACKER.include?(_attacker)
    return unless LOCATION.include?(_from)
    return unless LOCATION.include?(_to)
    return unless @state[ON].include?([_attacker, _from])
    return if @state[ON].include?([_attacker, _to])
    @state = @state.dup
    (@state[ON] = @state[ON].dup).delete([_attacker, _from])
    @state[ON].unshift([_attacker, _to])
    true
  end

  def map(_scout, _resource, _enemy, _location)
    return unless SCOUT.include?(_scout)
    return unless RESOURCE.include?(_resource)
    return unless ENEMY.include?(_enemy)
    return unless LOCATION.include?(_location)
    return unless @state[ON].include?([_scout, _location])
    return unless @state[EXIST].include?([_resource, _location])
    return if @state[EXIST].include?([_enemy, _location])
    @state = @state.dup
    (@state[ON] = @state[ON].dup).unshift([_resource, _location])
    true
  end

  def map_enemy(_scout, _resource, _enemy, _location)
    return unless SCOUT.include?(_scout)
    return unless RESOURCE.include?(_resource)
    return unless ENEMY.include?(_enemy)
    return unless LOCATION.include?(_location)
    return unless @state[ON].include?([_scout, _location])
    return unless @state[EXIST].include?([_resource, _location])
    return unless @state[EXIST].include?([_enemy, _location])
    @state = @state.dup
    (@state[ON] = @state[ON].dup).unshift([_resource, _location])
    @state[ON].unshift([_enemy, _location])
    true
  end

  def kill(_attacker, _enemy, _location)
    return unless ATTACKER.include?(_attacker)
    return unless ENEMY.include?(_enemy)
    return unless LOCATION.include?(_location)
    return unless @state[ON].include?([_attacker, _location])
    return unless @state[ON].include?([_enemy, _location])
    @state = @state.dup
    (@state[EXIST] = @state[EXIST].dup).delete([_enemy, _location])
    (@state[ON] = @state[ON].dup).delete([_enemy, _location])
    true
  end

  #-----------------------------------------------
  # Methods
  #-----------------------------------------------

  def grow_find_gather(_gatherer, _scout, _attacker)
    return unless GATHERER.include?(_gatherer)
    return unless SCOUT.include?(_scout)
    return unless @state[EMPTY].include?(_gatherer)
    @state[ON].each {|_gatherer_ground, _from|
      next if _gatherer_ground != _gatherer
      next unless @state[ON].include?([_scout, _from])
      next unless LOCATION.include?(_from)
      LOCATION.each {|_to|
        RESOURCE.each {|_resource|
          ENEMY.each {|_enemy|
            next if @state[EXIST].include?([_enemy, _to])
            yield [
              [:find, _scout, _from, _to],
              [:collect, _gatherer, _from, _to]
            ]
          }
        }
      }
    }
  end

  def grow_find_gather_attacker(_gatherer, _scout, _attacker)
    return unless GATHERER.include?(_gatherer)
    return unless SCOUT.include?(_scout)
    return unless ATTACKER.include?(_attacker)
    return unless @state[EMPTY].include?(_gatherer)
    @state[ON].each {|_attacker_ground, _from|
      next if _attacker_ground != _attacker
      next unless @state[ON].include?([_gatherer, _from])
      next unless @state[ON].include?([_scout, _from])
      next unless LOCATION.include?(_from)
      @state[EXIST].each {|_enemy, _to|
        next unless ENEMY.include?(_enemy)
        next unless LOCATION.include?(_to)
        RESOURCE.each {|_resource|
          yield [
            [:find, _scout, _from, _to],
            [:attack, _attacker, _from, _to],
            [:collect, _gatherer, _from, _to]
          ]
        }
      }
    }
  end

  def collect_collect(_gatherer, _from, _to)
    return unless @state[ON].include?([_gatherer, _from])
    return unless LOCATION.include?(_to)
    return unless @state[EMPTY].include?(_gatherer)
    return unless LOCATION.include?(_from)
    return unless GATHERER.include?(_gatherer)
    @state[ON].each {|_resource, _to_ground|
      next if _to_ground != _to
      next unless RESOURCE.include?(_resource)
      ENEMY.each {|_enemy|
        next if @state[EXIST].include?([_enemy, _to])
        yield [
          [:move, _gatherer, _from, _to],
          [:pickup, _gatherer, _resource],
          [:move, _gatherer, _to, _from],
          [:drop, _gatherer, _resource]
        ]
      }
    }
  end

  def find_find_not_enemy(_scout, _from, _to)
    return unless @state[ON].include?([_scout, _from])
    return unless SCOUT.include?(_scout)
    return unless LOCATION.include?(_from)
    return unless LOCATION.include?(_to)
    RESOURCE.each {|_resource|
      ENEMY.each {|_enemy|
        next if @state[EXIST].include?([_enemy, _to])
        yield [
          [:move_scout, _scout, _from, _to],
          [:map, _scout, _resource, _enemy, _to],
          [:move_scout, _scout, _to, _from]
        ]
      }
    }
  end

  def find_find_enemy(_scout, _from, _to)
    return unless @state[ON].include?([_scout, _from])
    return unless SCOUT.include?(_scout)
    return unless LOCATION.include?(_from)
    return unless LOCATION.include?(_to)
    @state[EXIST].each {|_enemy, _to_ground|
      next if _to_ground != _to
      next unless ENEMY.include?(_enemy)
      RESOURCE.each {|_resource|
        yield [
          [:move_scout, _scout, _from, _to],
          [:map_enemy, _scout, _resource, _enemy, _to],
          [:move_scout, _scout, _to, _from]
        ]
      }
    }
  end

  def attack_attack(_attacker, _from, _to)
    return unless @state[ON].include?([_attacker, _from])
    return unless ATTACKER.include?(_attacker)
    return unless LOCATION.include?(_from)
    return unless LOCATION.include?(_to)
    @state[EXIST].each {|_enemy, _to_ground|
      next if _to_ground != _to
      next unless ENEMY.include?(_enemy)
      yield [
        [:move_attacker, _attacker, _from, _to],
        [:kill, _attacker, _enemy, _to],
        [:move_attacker, _attacker, _to, _from]
      ]
    }
  end

  def visit_visit(_scout)
    return unless SCOUT.include?(_scout)
    @state[ON].each {|_scout_ground, _from|
      next if _scout_ground != _scout
      next unless LOCATION.include?(_from)
      LOCATION.each {|_to|
        next if @state[VISITED].include?(_to)
        yield [
          [:visit_scout, _scout, _from, _to],
          [:visit_scout, _scout, _to, _from]
        ]
      }
    }
  end
end