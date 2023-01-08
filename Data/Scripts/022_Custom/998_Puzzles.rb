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
  $game_switches[108] = $game_switches[102] && $game_switches[103] && $game_switches[104] && $game_switches[105]
end