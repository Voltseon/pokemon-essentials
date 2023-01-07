class PartnerSprite < IconSprite
  attr_accessor :partner_name
  def initialize(*args)
    super(args[0], args[1], args[2])
    @partner_name = ""
    @namebmp = BitmapSprite.new(128, 42, @viewport)
  end

  def partner_name=(value)
    @partner_name = value
  end

  def update
    super
    @namebmp.x = self.x + self.width / 2 - @namebmp.width / 2
    @namebmp.y = self.y - 24
    @namebmp.bitmap.clear
    @namebmp.update
    pbDrawTextPositions(@namebmp.bitmap, [@partner_name, @namebmp.x + @namebmp.width / 2, @namebmp.y + @namebmp.height / 2, 2, Color.new(248,248,248,128), Color.new(64,64,64,128)])
  end

  def dispose
    @namebmp.dispose
    super
  end

  def visible=(value)
    super
    @namebmp.visible = value
  end
end