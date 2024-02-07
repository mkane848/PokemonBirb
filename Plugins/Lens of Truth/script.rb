#===============================================================================
# **                   Eye/Lens of Truth for Essentials                       **
#                                 by Drimer
# **                    Updated for Pokemon Essentials v21
#                                  by KeMiX
#===============================================================================
# Events with '#EOT' on their names will be affected by this script.
#   If you want to hide an event appent the tag 'HIDE' or 'SHOW' to... show it!
#   
#   You can also add a third tag which must be a number and will be used as
#   the event limit opacity (to show or hide)
#
#   Examples:
#     #EOT HIDE
#     #EOT HIDE 100
#     #EOT SHOW
#     #EOF SHOW 100
#
#   The item must use the Flag 'LENSOFTRUTH'. Ex:
#     [LENSOFTRUTH]
#     Name = Lens of Truth
#     NamePlural = Lens of Truth
#     Pocket = 8
#     Price = 0
#     FieldUse = Direct
#     Flags = KeyItem, LensOfTruth
#     Description = Allows hidden truths to be revealed in the world...
#===============================================================================

module LensOfTruth
    # Time in seconds
    DURATION = 6
    # Range, max is 4
    RANGE = 3
  end
  
  class Scene_Map
    attr_accessor :eye_of_truth_time
    
    def initialize
      @eye_of_truth_time = 0
    end
  end
  
  class Game_Event
    attr_accessor :event, :opacity, :through, :character_hue
    
    alias _update_lens update
    def update
      if self.name[/#EOT/]
        if self.name[/HIDE/]
          if InRange?(self.event, LensOfTruth::RANGE%5) &&
              ($scene.is_a?(Scene_Map) ? $scene.eye_of_truth_time > 0 : false)
            opacity = self.name[/(\d+)/] ? $1.to_i : 0
            self.through = true
            self.opacity -= 25.5 if self.opacity > opacity
          else
            if !onEvent?
              self.through = false
            end
            self.opacity += 25.5 if self.opacity < 255
          end
        elsif self.name[/SHOW/]
          if InRange?(self.event, LensOfTruth::RANGE%5) &&
              ($scene.is_a?(Scene_Map) ? $scene.eye_of_truth_time > 0 : false)
            opacity = self.name[/(\d+)/] ? $1.to_i : 255
            if !onEvent?
              self.through = false
            end
            self.opacity += 25.5 if self.opacity < opacity
          else
            self.through = true
            self.opacity -= 25.5 if self.opacity > 0
          end        
        end
      end
      _update_lens
    end
    
    def InRange?(event, distance)
      return false if distance<=0
      rad = (Math.hypot((event.x - $game_player.x),(event.y - $game_player.y))).abs
      return true if (rad <= distance)
      return false
    end
  end
  
  module Graphics
    class << self
      alias _update_eye update
      def update
        _update_eye
        if !@eye_graphic || @eye_graphic.disposed?
          @eye_graphic = Sprite.new
          @eye_graphic.z = 3
          @eye_graphic.bitmap = RPG::Cache.load_bitmap("Graphics/Pictures/Lens/","truth_circle")
          @eye_graphic.ox = @eye_graphic.bitmap.width/2
          @eye_graphic.oy = @eye_graphic.bitmap.height/2
          @eye_graphic.x = Graphics.width/2
          @eye_graphic.y = Graphics.height/2
          @eye_graphic.opacity = 0
        end
        if !@mask || @mask.disposed?
          @mask = Sprite.new
          @mask.bitmap = RPG::Cache.load_bitmap("Graphics/Pictures/Lens/","mask")
          @mask.z = 1
          @mask.ox = @mask.bitmap.width/2
          @mask.oy = @mask.bitmap.height/2
          @mask.x = Graphics.width/2
          @mask.y = Graphics.height/2
          @mask.opacity = 0
        end
        if !@effect || @effect.disposed?
          @effect = Sprite.new
          @effect.z = 2
          @effect.bitmap = RPG::Cache.load_bitmap("Graphics/Pictures/Lens/","wave")
          @effect.ox = @effect.bitmap.width/2
          @effect.oy = @effect.bitmap.height/2
          @effect.x = Graphics.width/2
          @effect.y = Graphics.height/2
          @effect.zoom_x = @effect.zoom_y = 0
        end
        return if $game_temp && $game_temp.in_menu
        if $scene.is_a?(Scene_Map) && $scene.eye_of_truth_time > 0
          @effect.visible = true if !@effect.visible
          @mask.x = @eye_graphic.x = @effect.x = $game_player.screen_x
          @mask.y = @eye_graphic.y = @effect.y = $game_player.screen_y
          $scene.eye_of_truth_time -= 1
          if @eye_graphic.opacity < 255
            @eye_graphic.opacity += 25.5
            @mask.opacity += 25.5
          end
          if @effect.zoom_x < 1.0
            @effect.zoom_x = @effect.zoom_y += 0.025
          else
            if @effect.opacity > 0
              @effect.opacity -= 51
            else
              @effect.zoom_x = @effect.zoom_y = 0
              @effect.opacity = 255
            end
          end
          @eye_graphic.angle += 1
        else
          if @eye_graphic.opacity > 0
            @eye_graphic.angle += 1
            @eye_graphic.opacity -= 25.5 
            @mask.opacity -= 25.5
            @effect.visible = false
            @effect.opacity = 255
            @effect.zoom_x = @effect.zoom_y = 0
          end
        end
      end
    end
  end
  
  def pbLensOfTruth
    if ($scene.eye_of_truth_time == 0)
      return true
    else
      Kernel.pbMessage(_INTL("La Lente ya está siendo usada."))
      return false
    end
  end
  
  ItemHandlers::UseInField.add(:LENSOFTRUTH,proc{|item|
    Kernel.pbMessage(_INTL("¡\\PN usó Lente de la Verdad!"))
    waves = []
    star = Sprite.new
    star.z = 2
    star.bitmap = RPG::Cache.load_bitmap("Graphics/Pictures/Lens/","part")
    star.ox = star.bitmap.width/2
    star.oy = star.bitmap.height/2
    star.x = $game_player.screen_x
    star.y = $game_player.screen_y
    star.zoom_x = star.zoom_y = 0
    count = 0
    10.times do
      s = Sprite.new
      s.z = 1
      s.bitmap = RPG::Cache.load_bitmap("Graphics/Pictures/Lens/","wave")
      s.zoom_x = s.zoom_y = 0
      s.x = $game_player.screen_x
      s.y = $game_player.screen_y
      s.ox = s.bitmap.width/2
      s.oy = s.bitmap.height/2
      waves.push(s)
    end
    pbSEPlay("shiny")
    15.times do
      Graphics.update
      star.zoom_x = star.zoom_y += 1.0/15.0
      star.angle += 3
    end
    pbSEPlay("Saint6")
    30.times do
      Graphics.update
      star.angle += 3
      count += 1
      for i in 0...waves.length
        next if !waves[i].visible
        if waves[i].zoom_x >= 1.0
          waves[i].visible = false
        end
        waves[i].zoom_x = waves[i].zoom_y += 0.01*i
      end
    end
    5.times do
      Graphics.update
      for i in 0...waves.length
        next if !waves[i].visible
        if waves[i].zoom_x >= 1.0
          waves[i].visible = false
        end
        waves[i].zoom_x = waves[i].zoom_y += 0.01*i
        waves[i].opacity -= 255/5
      end
      star.zoom_x = star.zoom_y -= 1.0/5.0
      star.angle += 3
    end
    waves.each{|i| i.dispose}
    star.dispose
    $scene.eye_of_truth_time = LensOfTruth::DURATION * Graphics.frame_rate if $scene.is_a?(Scene_Map)
  })
  ItemHandlers::UseFromBag.add(:LENSOFTRUTH,proc{|item|
    if pbLensOfTruth
      next 2
    else
      next 0
    end
  })