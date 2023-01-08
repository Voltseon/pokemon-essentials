$Connection = nil
$Partner = nil
$LastVar = []
$Client_id = 0

module CableClub
  def self.session(msgwindow, partner_trainer_id)
    begin
      pbMessageDisplayDots(msgwindow, _INTL("Connecting"), 0)
      host,port = get_server_info
      Connection.open(host,port) do |connection|
        state = :await_server
        last_state = nil
        $Client_id = 0
        partner_name = nil
        partner_trainer_type = nil
        partner_party = nil
        frame = 0
        activity = nil
        seed = nil
        battle_type = nil
        chosen = nil
        partner_chosen = nil
        partner_confirm = false

        

        $Partner = PartnerSprite.new(0,0,Spriteset_Map.viewport)

        loop do
          if state != last_state
            last_state = state
            frame = 0
          else
            frame += 1
          end

          Graphics.update
          Input.update
          if Input.press?(Input::BACK)
            message = case state
              when :await_server; _INTL("Abort connection?\\^")
              when :await_partner; _INTL("Abort search?\\^")
              else; _INTL("Disconnect?\\^")
              end
            pbMessageDisplay(msgwindow, message)
            break if pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
          end

          case state
          # Waiting to be connected to the server.
          # Note: does nothing without a non-blocking connection.
          when :await_server
            if connection.can_send?
              connection.send do |writer|
                writer.sym(:find)
                writer.str(Settings::GAME_VERSION)
                writer.int(partner_trainer_id)
                writer.str($player.name)
                writer.int($player.id)
                writer.sym($player.online_trainer_type)
                write_party(writer)
              end
              state = :await_partner
            else
              pbMessageDisplayDots(msgwindow, _ISPRINTF("Your ID: {1:05d}\\nConnecting",$player.public_ID($player.id)), frame)
            end

          # Waiting to be connected to the partner.
          when :await_partner
            pbMessageDisplayDots(msgwindow, _ISPRINTF("Your ID: {1:05d}\\nSearching",$player.public_ID($player.id)), frame)
            connection.update do |record|
              case (type = record.sym)
              when :found
                $Client_id = record.int
                partner_name = record.str
                partner_trainer_type = record.sym
                partner_party = parse_party(record)
                $Partner.partner_name = partner_name
                #pbMessageDisplay(msgwindow, _INTL("{1} {2} connected!",GameData::TrainerType.get(partner_trainer_type).name, partner_name))
                state = :session

              else
                raise "Unknown message: #{type}"
              end
            end

          # Choosing an activity (leader only).
          when :session
            $Connection = connection
            $Partner.partner_id = partner_trainer_id
            $Partner.setBitmap(GameData::TrainerType.charset_filename(partner_trainer_type))
            $Partner.ox = $Partner.bitmap.width/4
            $Partner.ox = $Partner.bitmap.height/4
            break
          else
            raise "Unknown state: #{state}"
          end
        end
      end
    rescue
      $Connection = nil
      $Partner = nil
      $LastVar = []
      $Client_id = 0
    end
  end
end

def update_leader
  return if $Connection.nil?
  $Partner.update

  if $Connection.can_send?
    $Connection.send do |writer|
      writer.int($game_map.map_id)
      writer.int($game_player.x)
      writer.int($game_player.y)
      writer.int(($game_player.real_x*10).to_i)
      writer.int(($game_player.real_y*10).to_i)
      writer.int($game_player.x_offset)
      writer.int($game_player.y_offset)
      writer.int($game_player.direction)

      writer.str($game_player.character_name)
      writer.int($game_player.pattern)
      writer.bool($game_player.moving?)

      (76..100).each do |i|
        if $LastVar[i].is_a?(Array)
          writer.bool($LastVar[i][0])
          writer.int($LastVar[i][1])
        else
          writer.bool($game_switches[i])
          writer.int($game_variables[i])
        end
        writer.bool($game_switches[i])
        writer.int($game_variables[i])
      end
    end
  end

  $Connection.update do |record|
    mapinfo = pbLoadMapInfos
    $Partner.partner_map = record.int
    $Partner.partner_x = record.int
    $Partner.partner_y = record.int
    $Partner.visible = $Partner.partner_map == $game_map.map_id
=begin
    #dist = $map_factory.getRelativePos($game_map.map_id, $game_player.x, $game_player.y, $Partner.partner_map, $Partner.partner_x, $Partner.partner_y)
    #dist_normal = (dist[0] != 0 ? dist[1] / dist[0] : 0).abs
    if true#dist_normal < 10
      $Partner.visible = true
      if $Partner.partner_map != $game_map.map_id
        $Partner.visible = false
        MapFactoryHelper.eachConnectionForMap($game_map.map_id) do |conn|
          next unless conn[0] == $Partner.partner_map
          $Partner.visible = true
          break
        end
      end
    else
      $Partner.visible = true
    end
=end
    x = (((record.int/10).to_f - $map_factory.getMap($Partner.partner_map,false).display_x) / Game_Map::X_SUBPIXELS).round + 1.5 * Game_Map::TILE_WIDTH
    y = record.int
    z = (((y/10).to_f - $map_factory.getMap($Partner.partner_map,false).display_y) / Game_Map::Y_SUBPIXELS).round + Game_Map::TILE_HEIGHT
    y = (((y/10).to_f - $map_factory.getMap($Partner.partner_map,false).display_y) / Game_Map::Y_SUBPIXELS).round - Game_Map::TILE_HEIGHT / 2
    x += record.int
    y += record.int
    $Partner.x = x
    $Partner.y = y - 16
    $Partner.z = z
    direction = record.int

    $Partner.setBitmap("Graphics/Characters/#{record.str}")
    pattern = record.int
    src_x = record.bool ? pattern : 0
    $Partner.src_rect.set(src_x*$Partner.bitmap.width/4,((direction/2)-1)*$Partner.bitmap.height/4,$Partner.bitmap.width/4,$Partner.bitmap.height/4)
  
    (76..100).each do |i|
      last_switch = record.bool
      last_var = record.int
      switch = record.bool
      var = record.int
      $LastVar[i] = [$game_switches[i], $game_variables[i]]
      $game_switches[i] = switch if last_switch != switch
      $game_variables[i] = var if last_var != var
      if last_switch != switch || last_var != var
        $game_map.need_refresh = true
      end
    end
  end
end

module Graphics
  unless defined?(g_update)
    class << Graphics
      alias g_update update
    end
  end

  def self.update
    g_update
    update_leader
  end
end

def tpp
  $game_temp.player_transferring = true
  $game_temp.player_new_map_id    = $Partner.partner_map
  $game_temp.player_new_x         = $Partner.partner_x
  $game_temp.player_new_y         = $Partner.partner_y
end

EventHandlers.add(:on_player_interact, :talk_to_partner,
  proc {
    next if $Connection.nil?
    next if $Partner.partner_map != $game_map.map_id
    facing_tile = get_facing_tile
    next if $Partner.partner_x != facing_tile[0]
    next if $Partner.partner_y != facing_tile[1]
    next if $game_player.pbFacingEvent
    next if $game_player.pbFacingTerrainTag.can_surf_freely
    pbSEPlay("Vs flash")
  }
)

def get_facing_tile
  x=0
  y=0
  case $game_player.direction
  when 1
    x -= 1
    y += 1
  when 2
    y += 1
  when 3
    x += 1
    y += 1
  when 4
    x -= 1
  when 6
    x += 1
  when 7
    x -= 1
    y -= 1
  when 8
    y -= 1
  when 9
    x += 1
    y -= 1
  end
  x+=$game_player.x
  y+=$game_player.y
  return [x,y]
end