class PartnerSprite < IconSprite
  attr_accessor :partner_name

  NAME_BASE = Color.new(248,248,248,128)
  NAME_SHADOW = Color.new(64,64,64,128)

  def initialize(*args)
    super(args[0], args[1], args[2])
    @partner_name = ""
    @namebmp = BitmapSprite.new(Graphics.width, Graphics.height, args[2])
    pbSetSystemFont(@namebmp.bitmap)
    @namebmp.z = self.z + 1
  end

  def namebmp; @namebmp; end

  def partner_name=(value)
    @partner_name = value
  end

  def update
    @namebmp.z = self.z + 1
    @namebmp.bitmap.clear
    pbDrawTextPositions(@namebmp.bitmap, [[@partner_name, self.x + self.width / 8, self.y, 2, NAME_BASE, NAME_SHADOW]])
    super
  end

  def dispose
    @namebmp.bitmap.dispose
    @namebmp.dispose
    super
  end

  def visible=(value)
    @namebmp.visible = value
    super
  end
end