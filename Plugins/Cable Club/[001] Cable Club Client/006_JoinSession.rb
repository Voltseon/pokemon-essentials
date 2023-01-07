$Connection = nil
$Partner_sprite = nil

module CableClub
  def self.session(msgwindow, partner_trainer_id)
    pbMessageDisplayDots(msgwindow, _INTL("Connecting"), 0)
    host,port = get_server_info
    Connection.open(host,port) do |connection|
      state = :await_server
      last_state = nil
      client_id = 0
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

      

      $Partner_sprite = IconSprite.new(0,0,Spriteset_Map.viewport)

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
              client_id = record.int
              partner_name = record.str
              partner_trainer_type = record.sym
              partner_party = parse_party(record)
              #pbMessageDisplay(msgwindow, _INTL("{1} {2} connected!",GameData::TrainerType.get(partner_trainer_type).name, partner_name))
              state = :session

            else
              raise "Unknown message: #{type}"
            end
          end

        # Choosing an activity (leader only).
        when :session
          $Connection = connection
          $Partner_sprite.visible = false
          $Partner_sprite.setBitmap(GameData::TrainerType.charset_filename(partner_trainer_type))
          $Partner_sprite.ox = $Partner_sprite.bitmap.width/4
          $Partner_sprite.ox = $Partner_sprite.bitmap.height/4
          break
        else
          raise "Unknown state: #{state}"
        end
      end
    end
  end
end

def update_leader
  return if $Connection.nil?
  if $Connection.can_send?
    $Connection.send do |writer|
      writer.int($game_map.map_id)
      writer.int(($game_player.real_x*10).to_i)
      writer.int(($game_player.real_y*10).to_i)
      writer.int($game_player.x_offset)
      writer.int($game_player.y_offset)
      writer.int($game_player.direction)

      writer.str($game_player.character_name)
      writer.int($game_player.pattern)
      writer.bool($game_player.moving?)
    end
  end
  $Connection.update do |record|
    if record.int != $game_map.map_id
      $Partner_sprite.visible = false
      break
    end
    $Partner_sprite.visible = true
    x = (((record.int/10).to_f - $game_map.display_x) / Game_Map::X_SUBPIXELS).round + 1.5 * Game_Map::TILE_WIDTH
    y = record.int
    z = (((y/10).to_f - $game_map.display_y) / Game_Map::Y_SUBPIXELS).round + Game_Map::TILE_HEIGHT
    y = (((y/10).to_f - $game_map.display_y) / Game_Map::Y_SUBPIXELS).round - Game_Map::TILE_HEIGHT / 2
    x += record.int
    y += record.int
    $Partner_sprite.x = x
    $Partner_sprite.y = y
    $Partner_sprite.z = z
    direction = record.int

    $Partner_sprite.setBitmap("Graphics/Characters/#{record.str}")
    pattern = record.int
    src_x = record.bool ? 0 : pattern
    $Partner_sprite.src_rect.set(src_x,((direction/2)-1)*$Partner_sprite.bitmap.height/4,$Partner_sprite.bitmap.width/4,$Partner_sprite.bitmap.height/4)
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