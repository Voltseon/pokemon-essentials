class PartnerSprite < IconSprite
  attr_accessor :partner_name
  attr_accessor :partner_x
  attr_accessor :partner_y

  NAME_BASE = Color.new(248,248,248)
  NAME_SHADOW = Color.new(64,64,64)
  Y_OFFSET = 12

  def initialize(*args)
    super(args[0], args[1], args[2])
    @partner_name = ""
    @namebmp = BitmapSprite.new(Graphics.width, Graphics.height, args[2])
    @namebmp.opacity = 184
    @reflection = Sprite_Reflection.new(self, nil, args[2])
    pbSetNarrowFont(@namebmp.bitmap)
  end

  def drawpos; @drawpos; end
  def partner_x; @partner_x; end
  def partner_y; @partner_y; end

  def partner_x=(value); @partner_x = value; end
  def partner_y=(value); @partner_y = value; end
  def partner_name=(value); @partner_name = value; end

  def update
    @namebmp.z = self.z + 1
    @namebmp.bitmap.clear
    pbDrawTextPositions(@namebmp.bitmap, [[@partner_name, self.x-Game_Map::TILE_WIDTH, self.y-Y_OFFSET, 2, NAME_BASE, NAME_SHADOW]])
    @reflection&.update
    super
  end

  def dispose
    @namebmp.bitmap.dispose
    @namebmp.dispose
    @namebmp = nil
    @reflection&.dispose
    @reflection = nil
    super
  end

  def visible=(value)
    @namebmp.visible = value
    @reflection.visible = value
    super
  end

  def on_screen_x
    return self.x-self.ox <= Graphics.width && self.x-self.ox + self.bitmap.width >= 0
  end

  def on_screen_y
    return self.y-self.oy <= Graphics.height && self.y-self.oy + self.bitmap.height >= 0
  end

  def on_screen
    return on_screen_x && on_screen_y
  end
end