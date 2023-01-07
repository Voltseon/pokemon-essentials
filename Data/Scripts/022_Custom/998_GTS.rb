def pbListPokemon
  # Post method that gets read by the PHP
  check_listed = {
    :GTS_METHOD => "check_listed"
  }

  # Check if the webserver returns whether you already have a pokemon listed
  check_list = pbWebRequest(check_listed)
  if check_list != '0'
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
    :POKEMON_TO_LIST => [Zlib::Deflate.deflate(Marshal.dump(chosen_pokemon))].pack("m").gsub!("\n","Ö"),
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
  # Post method that gets read by the PHP
  check_listed = {
    :GTS_METHOD => "check_listed"
  }

  # Check if the webserver returns whether you already have a pokemon listed
  check_list = pbWebRequest(check_listed)
  if check_list == '0'
    pbMessage("You don't have a Pokémon listed!")
    return false
  end

  # Split the result into an array of strings
  result_array = check_list.split('&')

  # Get seperate values from array
  player_id = result_array[0]
  pokemon = result_array[1].gsub!("Ö","\n")
  pokemon = pbMysteryGiftDecrypt(pokemon)
  wanted_pkmn = result_array[2].to_sym
  wanted_gender = result_array[3]
  wanted_level = result_array[4]

  # Show the player the listed Pokémon
  pbMessage("#{pokemon.name} : #{wanted_pkmn} : #{wanted_gender} : #{wanted_level}")
end