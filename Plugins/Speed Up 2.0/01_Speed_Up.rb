module Input

  def self.update
    update_KGC_ScreenCapture
    if trigger?(Input::F8)
      pbScreenCapture
    end
    if $CanToggle && trigger?(Input::AUX1)
      $GameSpeed += 1
      if $GameSpeed >= SPEEDUP_STAGES.size
        $GameSpeed = 0
      end
    end
    if trigger?(Input::AUX2) && $DEBUG && !$InCommandLine
      $InCommandLine = true
      script = pbFreeTextNoWindow("",false,256,Graphics.width)
      $game_temp.lastcommand = script if !nil_or_empty?(script)
      begin
        pbMapInterpreter.execute_script(script) if !nil_or_empty?(script)
      rescue Exception
        echoln "The code crashed lol"
      end
      $InCommandLine = false
    end
  end
end

$InCommandLine = false

SPEEDUP_STAGES = [1,3]
$GameSpeed = 0
$frame = 0
$CanToggle = false

module Graphics
  class << Graphics
    alias fast_forward_update update
  end

  def self.update
    $frame += 1
    return unless $frame % SPEEDUP_STAGES[$GameSpeed] == 0
    fast_forward_update
    $frame = 0
  end
end

class Game_Temp
  attr_accessor :lastcommand

  def lastcommands
    @lastcommand = "" if !@lastcommand
    return @lastcommand
  end
end

def pbFreeTextNoWindow(currenttext, passwordbox, maxlength, width = 240)
  window = Window_TextEntry_Keyboard.new(currenttext, 0, 0, width, 64)
  ret = ""
  window.maxlength = maxlength
  window.visible = true
  window.z = 99999
  window.text = currenttext
  window.passwordChar = "*" if passwordbox
  Input.text_input = true
  loop do
    Graphics.update
    Input.update
    if Input.triggerex?(:ESCAPE)
      ret = currenttext
      break
    elsif Input.triggerex?(:RETURN)
      ret = window.text
      break
    end
    window.update
    yield if block_given?
  end
  Input.text_input = false
  window.dispose
  Input.update
  return ret
end