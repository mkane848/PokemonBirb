#===============================================================================
# Badgecase UI
# Are you tired of the old fashion badge case inside your trainer card? This plugin is for you!
#===============================================================================
# Badgecase_PBS
#===============================================================================
module GameData
  class Badge
    attr_reader :id
    attr_reader :real_name
    attr_reader :type
    attr_reader :leadername
    attr_reader :leadersprite
    attr_reader :location
    attr_reader :acepokemon
    attr_reader :order

    DATA = {}
    DATA_FILENAME = "badges.dat"

    SCHEMA = {
      "Name"         => [0, "s"],
      "InternalName" => [0, "s"],
      "Type"         => [0, "e", :Type],
      "LeaderName"   => [0, "s"],
      "LeaderSprite" => [0, "s"],
      "Location"     => [0, "s"],
      "AcePokemon"   => [0, "e", :Species],
      "Order"        => [0, "u"],
    }

    extend ClassMethodsSymbols
    include InstanceMethods

    def initialize(hash)
      @id           = hash[:id]
      @real_name    = hash[:name]         || "Something Badge"
      @type         = hash[:type]         || [:NORMAL]
      @leadername   = hash[:leadername]   || "Unnamed"
      @leadersprite = hash[:leadersprite] || "Leader_Brock"
      @location     = hash[:location]     || "Undefined Location"
      @acepokemon   = hash[:acepokemon]   || [:PIKACHU]
      @order        = hash[:order]        || 0
    end

    def id
      return pbGetMessageFromHash(MessageTypes::Badges,@id)
    end

    def name
      return pbGetMessageFromHash(MessageTypes::Badges,@real_name)
    end

    def type
      return @type
    end

    def leader_name
      return pbGetMessageFromHash(MessageTypes::Badges,@leadername)
    end

    def leader_sprite
      return pbGetMessageFromHash(MessageTypes::Badges,@leadersprite)
    end

    def location
      return pbGetMessageFromHash(MessageTypes::Badges,@location)
    end

    def ace_pokemon
      return @acepokemon
    end

    def order
      return @order
    end
  end

  class <<self
    alias_method :badge_load_all, :load_all
  end
  def self.load_all
    badge_load_all
    Badge.load
  end
end

#===============================================================================
#
#===============================================================================
module Badge_Compiler
  #=============================================================================
  # Compile Badges
  #=============================================================================
  def self.compile(path = "PBS/badges.txt")
    Compiler.compile_pbs_file_message_start(path)
    GameData::Badge::DATA.clear
    badge_names = []
    # Read from PBS file
    File.open(path, "rb") { |f|
      FileLineData.file = path   # For error reporting
      # Read a whole section's lines at once, then run through this code.
      # contents is a hash containing all the XXX=YYY lines in that section, where
      # the keys are the XXX and the values are the YYY (as unprocessed strings).
      schema = GameData::Badge::SCHEMA
      Compiler.pbEachFileSection(f) { |contents, badge_id|
        contents["InternalName"] = badge_id if !badge_id[/^\d+/]
        # Go through schema hash of compilable data and compile this section
        schema.each_key do |key|
          FileLineData.setSection(badge_id, key, contents[key])  # For error reporting
          # Skip empty properties, or raise an error if a required property is
          # empty
          if contents[key].nil?
            if ["Name", "InternalName"].include?(key)
              raise _INTL("The entry {1} is required in {2} section {3}.", key, path, type_id)
            end
            next
          end
          # Compile value for key
          value = Compiler.get_csv_record(contents[key], schema[key])
          value = nil if value.is_a?(Array) && value.empty?
          contents[key] = value
        end
        # Construct type hash
        badge_hash = {
          :id           => contents["InternalName"].to_sym,
          :name         => contents["Name"],
          :type         => contents["Type"],
          :leadername   => contents["LeaderName"],
          :leadersprite => contents["LeaderSprite"],
          :location     => contents["Location"],
          :acepokemon   => contents["AcePokemon"],
          :order        => contents["Order"]
        }
        # Add badge's data to records
        GameData::Badge.register(badge_hash)
        badge_names.push(badge_hash[:name])
      }
    }
    # Save all data
    GameData::Badge.save
    MessageTypes.setMessagesAsHash(MessageTypes::Badges, badge_names)
    Compiler.process_pbs_file_message_end
  end

  def self.write(path = "PBS/badges.txt")
    Compiler.write_pbs_file_message_start(path)
    File.open(path, "wb") { |f|
      Compiler.add_PBS_header_to_file(f)
      # Write each type in turn
      GameData::Badge.each do |badge|
        f.write("\#-------------------------------\r\n")
        f.write("[#{badge.id}]\r\n")
        f.write("Name = #{badge.real_name}\r\n")
        f.write("Type = #{badge.type}\r\n")
        f.write("LeaderName = #{badge.leadername}\r\n")
        f.write("LeaderSprite = #{badge.leadersprite}\r\n")
        f.write("Location = #{badge.location}\r\n")
        f.write("AcePokemon = #{badge.acepokemon}\r\n")
        f.write("Order = #{badge.order}\r\n")
      end
    }
    Compiler.process_pbs_file_message_end
  end
end

#===============================================================================
#
#===============================================================================

module MessageTypes
  Badges = 28
end

#===============================================================================
#
#===============================================================================

module Compiler
  class << Compiler
    alias badges_compile_pbs compile_pbs_files
    alias badges_write_pbs write_all
  end

  def self.compile_pbs_files
    badges_compile_pbs
    Badge_Compiler.compile
  end

  def self.write_all
    badges_write_pbs
    Badge_Compiler.write
  end

  def self.write_badges
    Badge_Compiler.write
  end
end