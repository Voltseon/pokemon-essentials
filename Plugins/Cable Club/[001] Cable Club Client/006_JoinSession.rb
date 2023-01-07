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

      partner_event = pbMapInterpreter.get_character(13)

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
              pbMessageDisplay(msgwindow, _INTL("{1} {2} connected!",GameData::TrainerType.get(partner_trainer_type).name, partner_name))
              state = :session

            else
              raise "Unknown message: #{type}"
            end
          end

        # Choosing an activity (leader only).
        when :session
          if connection.can_send?
            connection.send do |writer|
              writer.int($game_map.map_id)
              writer.int($game_player.x)
              writer.int($game_player.y)
              writer.int($game_player.direction)
            end
          end
          connection.update do |record|
            connection.dispose if record.int != $game_map.map_id
            partner_event.moveto(record.int,record.int)
            partner_event.direction = record.int
            partner_event.character_name = GameData::TrainerType.charset_filename_brief(partner_trainer_type)
          end
        else
          raise "Unknown state: #{state}"
        end
      end
    connection.dispose
    end
  end
end