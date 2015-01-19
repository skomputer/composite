require 'rmagick'

class CompositeImageList
  def initialize(input_filenames, num=10, random=false)
    input_filenames = input_filenames.shuffle.take(num) if random
    @images = Magick::ImageList.new(*input_filenames)
    @num = num
  end

  def remove_horizontal_inputs
    count = @images.count
    @images = @images.to_a.keep_if { |img| img.columns <= img.rows }
    print "removed #{count - @images.count} horizontal images\n"
  end

  def remove_vertical_inputs
    count = @images.count
    @images = @images.to_a.keep_if { |img| img.columns >= img.rows }
    print "removed #{count - @images.count} vertical images\n"
  end

  def width
    @width ||= compute_width
  end

  def compute_width
    widths = @images.to_a.collect { |img| img.columns }
    @width = widths.min
  end

  def height
    @height ||= compute_height
  end

  def compute_height
    heights = @images.to_a.collect { |img| img.rows }
    @height = heights.min
  end

  def images
    @images
  end
end