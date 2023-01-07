=begin
module Graphics
  unless defined?(g_update)
    class << Graphics
      alias g_update update
    end
  end

  def self.update
    g_update
    if $game_player
      $game_player.update
      $game_system.update
      $game_screen.update
    end
    if $scene.respond_to?(:updateSprites)
      $scene.updateMaps
      $scene.updateSpritesets
    end
  end
end
=end