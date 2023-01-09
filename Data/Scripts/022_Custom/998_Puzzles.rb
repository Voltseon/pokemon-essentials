def toggle_lamp_one
  $game_switches[102] = !$game_switches[102]
  check_solution
  $game_map.need_refresh = true
end

def toggle_lamp_two
  $game_switches[103] = !$game_switches[103]
  check_solution
  $game_map.need_refresh = true
end

def toggle_lamp_three
  $game_switches[104] = !$game_switches[104]
  check_solution
  $game_map.need_refresh = true
end

def toggle_lamp_four
  $game_switches[105] = !$game_switches[105]
  check_solution
  $game_map.need_refresh = true
end

def toggle_lamp_five
  $game_switches[106] = !$game_switches[106]
  check_solution
  $game_map.need_refresh = true
end

def toggle_lamp_six
  $game_switches[107] = !$game_switches[107]
  check_solution
  $game_map.need_refresh = true
end

def check_solution
  $game_switches[108] = true if $game_switches[102] && $game_switches[103] && $game_switches[104] && $game_switches[105]
end

def puzzle_three
  $game_map.events.each_value do |event|
    pbSetSelfSwitch(event.id, "A", false)
  end
  (-1..1).each do |x|
    (-1..1).each do |y|
      id = $game_map.check_event($Partner.partner_x+x,$Partner.partner_y+y)
      next unless id
      pbSetSelfSwitch(id, "A", true)
    end
  end
end