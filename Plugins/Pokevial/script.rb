#==============================================================================
# **                   Pokévial - for Pokémon Essentials v16.3             ** #
#                                 adapted by Skyflyer                         #
# **                    Updated for Pokemon Essentials v21                 ** #
#                                  by KeMiX                                   #
#==============================================================================

module Pokevial
    # VARIABLES USED (change the number if you prefer to use others)
    CURRENT_USES = 238
    MAX_USES = 239

    ItemHandlers::UseFromBag.add(:POKEVIAL,proc{|item|
        if $game_variables[CURRENT_USES]==1
            Kernel.pbMessage(_INTL("You have {1} heal available out of a maximum of {2}.", 
                $game_variables[CURRENT_USES], $game_variables[MAX_USES]))
        elsif $game_variables[CURRENT_USES]>1
            Kernel.pbMessage(_INTL("You have {1} heals available out of a maximum of {2}.", 
                $game_variables[CURRENT_USES], $game_variables[MAX_USES]))
        else
            Kernel.pbMessage(_INTL("The Pokévial is empty. Refill it at the Pokémon Center.", 
                $game_variables[MAX_USES]))
            next 0
        end
        if Kernel.pbConfirmMessage(_INTL("Heal your team with the Pokévial?"))
            for i in $player.party
                i.heal
            end
            Kernel.pbMessage(_INTL("Your team has been healed!"))
            $game_variables[CURRENT_USES] = $game_variables[CURRENT_USES]-1
        end
        next 0
        #next 1
    })
end