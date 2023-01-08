def pbGTSCheckIfListedPokemon
  # Check if the webserver returns whether you already have a pokemon listed
  return pbWebRequest({:GTS_METHOD => "check_listed"})
end

def pbListPokemon
  # Check if you already have a Pokémon listed
  if pbGTSCheckIfListedPokemon != '0'
    pbMessage("You already have a Pokémon listed!")
    return false
  end

  # Select a Pokémon from your PC to list
  scene = PokemonStorageScene.new
  screen = PokemonStorageScreen.new(scene, $PokemonStorage)
  chosen_pokemon_num = screen.pbChoosePokemon
  chosen_pokemon = $PokemonStorage[chosen_pokemon_num[0], chosen_pokemon_num[1]]
  pkmn_name = chosen_pokemon.name

  # Create a list of all seen Pokémon
  seen_pokemon = []
  seen_pokemon_names = []
  seen_pokemon_data = []
  GameData::Species.each do |species|
    next unless $player.seen?(species.id)
    seen_pokemon << species.id
    seen_pokemon_names << species.name
    seen_pokemon_data << species
  end

  # Select which Pokémon you want to ask for
  pkmn_choice = pbMessage("Which Pokémon would you like to get?", seen_pokemon_names, -1)
  if pkmn_choice == -1
    pbMessage("Cancelling...")
    return false
  end

  # Select what gender the asked Pokémon should be
  gender_options = ["Any"]
  gender_choice = 0
  selected_pokemon = seen_pokemon_data[pkmn_choice]
  gender_options << "Male" if selected_pokemon.gender_ratio == :AlwaysMale || !selected_pokemon.single_gendered?
  gender_options << "Female" if selected_pokemon.gender_ratio == :AlwaysFemale || !selected_pokemon.single_gendered?
  if gender_options.length > 0
    gender_choice = pbMessage("What gender would you like to get?", gender_options, -1)
    if gender_choice == -1
      pbMessage("Cancelling...")
      return false
    end
  end

  # Select what level the asked Pokémon should be
  level_options = ["Any"]
  (Settings::MAXIMUM_LEVEL/10).times do |i|
    level_options << "#{(i+1)*10}"
  end
  level_choice = pbMessage("Which level should the Pokémon you like to get at least be?", level_options, -1)
  if level_choice == -1
    pbMessage("Cancelling...")
    return false
  end

  # Select what language the asked Pokémon should be (skip for now)

  # Make a web request to the server to list the request
  list_pokemon = {
    :GTS_METHOD => "list_pokemon",
    :POKEMON_TO_LIST => chosen_pokemon.encrypt,
    :WANTED_POKEMON => seen_pokemon[pkmn_choice],
    :WANTED_GENDER => gender_options[gender_choice],
    :WANTED_LEVEL => "#{level_options[level_choice]}"
  }
  result = pbWebRequest(list_pokemon)
  echoln result

  # Remove the Pokémon from your PC
  $PokemonStorage[chosen_pokemon_num[0], chosen_pokemon_num[1]] = nil if result == 'success'

  # Save the game
  Game.save

  # Tell the player whether it was successful
  if result == 'success'
    pbMessage("Successfully posted #{pkmn_name}")
  else
    pbMessage("Something went wrong with depositing the Pokémon")
  end
end

def pbCheckListed
  check_list = pbGTSCheckIfListedPokemon
  if check_list == '0'
    pbMessage("You don't have any Pokémon listed.")
    return false
  end

  # Split the result into an array of strings
  result_array = check_list.split('&')

  # Get seperate values from array
  player_id = result_array[0]
  pokemon = result_array[1]
  pokemon = decryptPokemon(pokemon)
  wanted_pkmn = result_array[2].to_sym
  wanted_gender = result_array[3]
  wanted_level = result_array[4]

  # Show the player the listed Pokémon
  pbMessage("#{wanted_pkmn} : #{wanted_gender} : #{wanted_level}")
  scene = PokemonSummary_Scene.new
  screen = PokemonSummaryScreen.new(scene)
  screen.pbStartScreen([pokemon], 0)
  if pbConfirmMessage("Would you like to get your Pokémon back?")
    if pbGTSCheckIfListedPokemon == '0'
      pbMessage('Your Pokémon was taken from the GTS.')
      return false
    end
    check_deletion = pbWebRequest({:GTS_METHOD => "remove_listed"}) == "success"
    if check_deletion
      pbAddPokemon(pokemon)
    else
      echoln check_deletion
      pbMessage("Something went wrong with taking the Pokémon")
    end
  end
end

def pbGetList(pokemon=nil)
  # Make request for the list
  pokemon_check = (pokemon.nil? ? "None" : pokemon.to_s)
  raw_list = pbWebRequest({
    :GTS_METHOD => "get_list",
    :POKEMON_TO_LIST => pokemon_check
    }
  )

  # Check if there was a returned list; A successful response adds the 'ö' character at the start of the result
  if raw_list[0] != "ö"
    echoln raw_list
    pbMessage("There are nö Pokémon listed with these settings.")
    return false
  end

  # Remove the ö character at the start
  raw_list = raw_list[1..-1] 

  # Convert return data to usable variables
  gts_list = raw_list.split(":::") # Each listing is seperated by a ':::'
  gts_list.each do |listing| # Iterate each single listing
    # Each element in the listing is seperated by a '^^^'
    listing.split("^^^")
    # Pokémon
    listing[0] = decryptPokemon(listing[0])
    # Wanted Pokémon
    listing[1] = listing[1].to_sym
    # Wanted Gender
    listing[2] = listing[2]
    # Wanted Level
    listing[3] = listing[3]
  end

  # Check if there actually was a list (fail save)
  if gts_list.length == 0
    echoln gts_list
    pbMessage("There are no Pokémon listed with these settings.")
    return false
  end

  # Return the list
  return gts_list
end