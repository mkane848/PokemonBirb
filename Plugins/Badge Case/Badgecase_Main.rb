#===============================================================================
# Badgecase UI
# Are you tired of the old fashion badge case inside your trainer card? This plugin is for you!
#===============================================================================
# Badgecase_Main
# Main script for the plugin's backend
#===============================================================================
class Badgecase
  attr_accessor :obtained_badges
  attr_accessor :unobtained_badges
  attr_accessor :unused_badges
  attr_accessor :obtained_time

  def initialize
    @obtained_badges = []
    @unobtained_badges = []
    @unused_badges = []
    @obtained_time = {}
    GameData::Badge.each do |badge|
      @unobtained_badges.push(badge.id)
    end
  end

  def updated_data
    @obtained_badges = @obtained_badges.select {|badge| !GameData::Badge.try_get(badge).nil?}
    @unobtained_badges = @unobtained_badges.select {|badge| !GameData::Badge.try_get(badge).nil?}
    @unused_badges = @unused_badges.select {|badge| !GameData::Badge.try_get(badge).nil?}
    badges = (@obtained_badges + @unobtained_badges + @unused_badges).to_a
    GameData::Badge.each { |badge|
      if badges.include?(badge.id)
        next
      else
        @unobtained_badges.push(badge.id)
      end
    }
  end

  def all_badges
    updated_data
    badge_list = (@obtained_badges + @unobtained_badges + @unused_badges).to_a
    badge_list = badge_list.sort_by { |badge| GameData::Badge.try_get(badge).order }
    return badge_list
  end

  def all_badges_information
    updated_data
    badges = all_badges
    badge_list = []
    badges.each { |badge_id|
      badge = GameData::Badge.try_get(badge_id)
      badge_list.push(badge) if !badge.nil?
    }
    return badge_list
  end

  def addBadge(badge)
    updated_data
    return if GameData::Badge.try_get(badge).nil?
    for i in 0...@unobtained_badges.length
      if @unobtained_badges[i] == badge
        return
      end
    end
    for i in 0...@obtained_badges.length
      if @obtained_badges[i] == badge
        return
      end
    end
    for i in 0...@unused_badges.length
      if @unused_badges[i] == badge
        @unobtained_badges.push(badge)
        @unused_badges.delete_at(i)
        return
      end
    end
  end

  def removeBadge(badge)
    updated_data
    for i in 0...@unobtained_badges.length
      if @unobtained_badges[i] == badge
        @unused_badges.push(badge)
        @unobtained_badges.delete_at(i)
        return
      end
    end
    for i in 0...@obtained_badges.length
      if @obtained_badges[i] == badge
        @unused_badges.push(badge)
        @obtained_badges.delete_at(i)
        return
      end
    end
  end

  def getBadge(badge)
    updated_data
    for i in 0...@obtained_badges.length
      if @obtained_badges[i] == badge
        return
      end
    end
    for i in 0...@unobtained_badges.length
      if @unobtained_badges[i] == badge
        @obtained_badges.push(@unobtained_badges[i])
        sym = @unobtained_badges[i].to_sym
        @obtained_time[sym] = pbGetTimeNow
        @unobtained_badges.delete_at(i)
        break
      end
    end
  end

  def loseBadge(badge)
    updated_data
    for i in 0...@unobtained_badges.length
      if @unobtained_badges[i] == badge
        return
      end
    end
    for i in 0...@obtained_badges.length
      if @obtained_badges[i] == badge
        @unobtained_badges.push(@obtained_badges[i])
        @obtained_badges.delete_at(i)
        break
      end
    end
  end

  def get_time(badge)
    updated_data
    ret = nil
    ret = @obtained_time[badge] if @obtained_badges.include?(badge)
    return ret
  end

  def badge_count
    updated_data
    return @obtained_badges.length
  end

  def badge_max
    updated_data
    return (@obtained_badges.length + @unobtained_badges.length)
  end

  def has?(badge)
    return @obtained_badges.include?(badge)
  end
end

#===============================================================================
# Adding badge data to our game storage
#===============================================================================
class PokemonGlobalMetadata

  def badges
    @badges = Badgecase.new if !@badges
    return @badges
  end

  alias badgecase_initialization initialize
  def initialize
    badgecase_initialization
    @badges = Badgecase.new
  end
end

#===============================================================================
# Changing and adding functions for our $player
# Added the function $player.badge_max (get the maximum number the player can obtain)
#===============================================================================
class Player < Trainer

  def badge_count
    return 0 if !$PokemonGlobal
    return $PokemonGlobal.badges.badge_count
  end

  def badge_max
    return 0 if !$PokemonGlobal
    return $PokemonGlobal.badges.badge_max
  end
end

#===============================================================================
# Changing the DEBUG menu for badges
#===============================================================================

MenuHandlers.add(:debug_menu, :set_badges, {
  "name"        => _INTL("Set Badges"),
  "parent"      => :player_menu,
  "description" => _INTL("Toggle possession of each Gym Badge."),
  "effect"      => proc {
    badges = $PokemonGlobal.badges.all_badges
    badgecmd = 0
    loop do
      badgecmds = []
      badgecmds.push(_INTL("Give all"))
      badgecmds.push(_INTL("Remove all"))
      badgecmds.push(_INTL("Update PBS from module"))
      badges.length.times do |i|
        badgecmds.push(_INTL("{1} {2}", ($PokemonGlobal.badges.has?(badges[i])) ? "[Y]" : "[  ]", GameData::Badge.try_get(badges[i]).name))
      end
      badgecmd = pbShowCommands(nil, badgecmds, -1, badgecmd)
      break if badgecmd < 0
      case badgecmd
      when 0   # Give all
        badges.length.times { |i| getBadge(badges[i]) }
      when 1   # Remove all
        badges.length.times { |i| loseBadge(badges[i]) }
      when 2   # Update PBS from module
        GameData::Badge::DATA.clear
        for i in 0...Badges::BADGES.length
          badge = Badge.new(Badges::BADGES[i][:ID],Badges::BADGES[i][:NAME],Badges::BADGES[i][:TYPE],Badges::BADGES[i][:LEADERNAME],Badges::BADGES[i][:LEADERSPRITE],Badges::BADGES[i][:LOCATION],Badges::BADGES[i][:ACEPOKEMON])
          badge_hash = {
            :id           => badge.id,
            :name         => badge.name,
            :type         => badge.type.upcase,
            :leadername   => badge.leadername,
            :leadersprite => badge.leadersprite,
            :location     => badge.location,
            :acepokemon   => badge.acepokemon.upcase,
            :order        => badge.order
          }
          GameData::Badge.register(badge_hash)
          GameData::Badge.save
        end
        Compiler.write_badges
        pbMessage(_INTL("The badges data was added to PBS/badges.txt."))
      else
        ($PokemonGlobal.badges.has?(badges[badgecmd - 3]))? loseBadge(badges[badgecmd - 3]) : getBadge(badges[badgecmd - 3])
      end
    end
  }
})

MenuHandlers.add(:debug_menu, :create_pbs_files, {
  "name"        => _INTL("Create PBS File(s)"),
  "parent"      => :other_menu,
  "description" => _INTL("Choose one or all PBS files and create it."),
  "effect"      => proc {
    cmd = 0
    cmds = [
      _INTL("[Create all]"),
      "abilities.txt",
      "battle_facility_lists.txt",
      "berry_plants.txt",
      "encounters.txt",
      "items.txt",
      "map_connections.txt",
      "map_metadata.txt",
      "metadata.txt",
      "moves.txt",
      "phone.txt",
      "pokemon.txt",
      "pokemon_forms.txt",
      "pokemon_metrics.txt",
      "regional_dexes.txt",
      "ribbons.txt",
      "shadow_pokemon.txt",
      "town_map.txt",
      "trainer_types.txt",
      "trainers.txt",
      "types.txt",
      "badges.txt"
    ]
    loop do
      cmd = pbShowCommands(nil, cmds, -1, cmd)
      case cmd
      when 0  then Compiler.write_all
      when 1  then Compiler.write_abilities
      when 2  then Compiler.write_trainer_lists
      when 3  then Compiler.write_berry_plants
      when 4  then Compiler.write_encounters
      when 5  then Compiler.write_items
      when 6  then Compiler.write_connections
      when 7  then Compiler.write_map_metadata
      when 8  then Compiler.write_metadata
      when 9  then Compiler.write_moves
      when 10 then Compiler.write_phone
      when 11 then Compiler.write_pokemon
      when 12 then Compiler.write_pokemon_forms
      when 13 then Compiler.write_pokemon_metrics
      when 14 then Compiler.write_regional_dexes
      when 15 then Compiler.write_ribbons
      when 16 then Compiler.write_shadow_pokemon
      when 17 then Compiler.write_town_map
      when 18 then Compiler.write_trainer_types
      when 19 then Compiler.write_trainers
      when 20 then Compiler.write_types
      when 21 then Compiler.write_badges
      else break
      end
      pbMessage(_INTL("File written."))
    end
  }
})

#===============================================================================
# Two helping functions, you should not use them
# addBadge(badge)- Adding a badge data to our badgelist
# getBadge(badge)- Moving a badge from the unobtained list to the obtained list
#===============================================================================
def addBadge(badge)
  return if !$PokemonGlobal
  $PokemonGlobal.badges.addBadge(badge)
end

def removeBadge(badge)
  return if !$PokemonGlobal
  $PokemonGlobal.badges.removeBadge(badge)
end

def getBadge(badge)
  return if !$PokemonGlobal
  $PokemonGlobal.badges.getBadge(badge)
end

def loseBadge(badge)
  return if !$PokemonGlobal
  $PokemonGlobal.badges.loseBadge(badge)
end