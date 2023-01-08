class Pokemon
  def encrypt
    m = ""
    @moves.each { |move| m+="#{GameData::Move.get(move.id).id}~" }
    fm = ""
    @first_moves.each { |move| fm+="#{GameData::Move.get(move).id}~" }
    r = ""
    @ribbons.each { |ribbon| r+="#{GameData::Ribbon.get(ribbon).id}~" }
    e = ""
    i = ""
    im = ""
    GameData::Stat.each do |stat|
      e+="#{@ev[stat.id]}~"
      i+="#{@iv[stat.id]}~"
      im+="#{@ivMaxed[stat.id]}~"
    end
    ow = "#{@owner.id}~#{@owner.name}~#{@owner.gender}~#{@owner.language}"
    item = GameData::Item.try_get(@item)
    item = item.id if item.respond_to?(:id)
    ret = "#{@species}~#{@level}~#{@form}~#{@ability}~#{@forced_form}~#{@exp}~#{@shiny}~#{@ability_index}~#{@pokerus}~#{GameData::Item.get(@poke_ball).id}~#{@markings}~#{@cool}~#{@beauty}~#{@smart}~#{@cute}~#{@tough}~#{@sheen}~#{@personalID}~#{@hatched_map}~#{@obtain_method}~#{@obtain_map}~#{@obtain_text}~#{@obtain_level}~#{i}#{e}#{im}~#{@gender}~#{GameData::Nature.get(@nature).id}~#{item}~#{ow}~#{@name}~#{@happiness}~#{@moves.length}~#{m}~#{@first_moves.length}~#{fm}#{r.length}~#{r}blah"
    return ret
  end
end

def decryptPokemon(data)
  data_array = data.split('~')
  owner = Pokemon::Owner.new(data_array[51].to_i,data_array[52],data_array[53].to_i,data_array[54].to_i)
  pkmn = Pokemon.new(data_array[0].to_sym, data_array[1].to_i,owner,true,true)
  pkmn.setForm(data_array[2].to_i)
  pkmn.ability = data_array[3]
  pkmn.forced_form = data_array[4].to_i
  pkmn.exp = data_array[5].to_i
  pkmn.shiny = data_array[6] == "true"
  pkmn.ability_index = data_array[7].to_i
  pkmn.pokerus = data_array[8].to_i
  pkmn.poke_ball = GameData::Item.get(data_array[9]).id
  pkmn.markings = data_array[10].to_i
  pkmn.cool = data_array[11].to_i
  pkmn.beauty = data_array[12].to_i
  pkmn.smart = data_array[13].to_i
  pkmn.cute = data_array[14].to_i
  pkmn.tough = data_array[15].to_i
  pkmn.sheen = data_array[16].to_i
  pkmn.personalID = data_array[17].to_i
  pkmn.hatched_map = data_array[18].to_i
  pkmn.obtain_method = data_array[19].to_i
  pkmn.obtain_map = data_array[20].to_i
  pkmn.obtain_text = data_array[21]
  pkmn.obtain_level = data_array[22].to_i
  index = 0
  GameData::Stat.each_main do |stat|
    next if ![:HP, :ATTACK, :DEFENSE, :SPEED, :SPECIAL_ATTACK, :SPECIAL_DEFENSE].include?(stat.id)
    pkmn.iv[stat.id] = data_array[23 + index].to_i
    pkmn.ev[stat.id] = data_array[31 + index].to_i
    pkmn.ivMaxed[stat.id] = data_array[35 + index] == "true"
    index += 1
  end
  pkmn.makeFemale if data_array[48].to_i == 1
  pkmn.nature = GameData::Nature.get(data_array[49]).id
  item = GameData::Item.try_get(data_array[50])
  pkmn.item = item.id if item.respond_to?(:id)
  pkmn.name = data_array[55]
  pkmn.happiness = data_array[56].to_i if owner.id == $Trainer.id
  pkmn.moves = []
  for i in 0...data_array[57].to_i
    break if nil_or_empty?(data_array[58+i])
    move = GameData::Move.try_get(data_array[58+i])
    next if move.nil?
    pkmn.moves.push(Pokemon::Move.new(move.id))
  end
  for j in 0...data_array[63].to_i
    break if nil_or_empty?(data_array[64+j])
    move = GameData::Move.try_get(data_array[64+j])
    next if move.nil?
    pkmn.first_moves.push(move.id)
  end
  ribbon_count = data_array[64 + data_array[63].to_i].to_i
  if ribbon_count != "blah"
    for k in 0...ribbon_count
      break if data_array[ribbon_count+k] == "blah"
      ribbon = GameData::Ribbon.try_get(data_array[ribbon_count+k])
      next if ribbon.nil?
      pkmn.ribbons.push(ribbon.id)
    end
  end
  pkmn.calc_stats
  return pkmn
end