class PartnerSprite < IconSprite
  attr_accessor :name
  def initialize(*args)
    super(args)
    @name = ""
    @namebmp = BitmapSprite.new(128, 42, @viewport)
  end

  def name=(value)
    @name = value
  end

  def update
    super
    @namebmp.x = self.x + self.width / 2 - @namebmp.width / 2
    @namebmp.y = self.y - 24
    @namebmp.bitmap.clear
    pbDrawTextPositions(@namebmp.bitmap, [@name, @namebmp.x + @namebmp.width / 2, @namebmp.y, 2, Color.new(248,248,248,128), Color.new(64,64,64,128)])
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