#==============================================================================
# **       PokéRider and Surf Mount - for Pokémon Essentials v16.3         ** #
#                           taken from Pokemon Anil                           #
# **                    Updated for Pokemon Essentials v21                 ** #
#                                  by KeMiX                                   #
#==============================================================================
module RiderAndMount
    ItemHandlers::UseFromBag.add(:POKERIDER,proc{|item|
        # outdoors=pbGetMetadata($game_map.map_id,MetadataOutdoor)
        if !$game_map.metadata&.outdoor_map
        # if !outdoors
            Kernel.pbMessage(_INTL("You can't use that here."))
            next 0
        end
        next 2
    })

    ItemHandlers::UseInField.add(:POKERIDER,proc{|item|
        # outdoors=pbGetMetadata($game_map.map_id,MetadataOutdoor)
        # if !outdoors
        if !$game_map.metadata&.outdoor_map
            Kernel.pbMessage(_INTL("No puedes viajar aquí."))
            next 0
        end
        useMoveFly
    })
end

def useMoveFly # Add useMoveFly in the event in a script command
    scene = PokemonRegionMap_Scene.new(-1,false)
    screen = PokemonRegionMapScreen.new(scene)
    ret = screen.pbStartFlyScreen
    return false if !ret
    $game_temp.fly_destination=ret
    #if !$game_temp.fly_destination
    # Kernel.pbMessage(_INTL("No puedes usarlo aquí."))
    #end
    pbFadeOutIn(99999){
        Kernel.pbCancelVehicles
        $game_temp.player_new_map_id=$game_temp.fly_destination[0]
        $game_temp.player_new_x=$game_temp.fly_destination[1]
        $game_temp.player_new_y=$game_temp.fly_destination[2]
        $game_temp.fly_destination=nil
        $game_temp.player_new_direction=2
        $scene.transfer_player
        $game_map.autoplay
        $game_map.refresh
    }   
    pbEraseEscapePoint
    return true
end