require 'rmagick'
require 'distribution'

class CompositeImage
  def initialize(list, outname, debug=true)
    @input_list = list
    @outname = outname
    @debug = true
  end

  def log(*strs)
    print(*strs) if @debug
  end

  def images
    @input_list.images.to_a
  end

  def num
    images.count
  end

  def height
    @input_list.height
  end

  def width
    @input_list.width
  end

  def calculate_pixel
    throw "calculate_pixel not defined"
  end

  def build_output_image
    log "\n"

    output_data = (0..height-1).to_a.map do |y|
      log "\rbuilding row #{y+1} out of #{height}..."
      images.map do |i| 
        i.dispatch(0, y, width, 1, "RGB")
      end.transpose.each_slice(3).map.with_index do |data, x| 
        calculate_pixel(x, y, *data)
      end
    end.flatten

    @output_image = Magick::Image.constitute(width, height, "RGB", output_data)

    log "\n"
  end

  def write_output_image
    @output_image.write(@outname)
  end
end

class MedianCompositeImage < CompositeImage
  def median(ary)
    sorted = ary.sort
    len = sorted.count
    (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end

  def calculate_pixel(x, y, reds, greens, blues)
    [reds, greens, blues].map do |ary|
      median(ary)
    end
  end
end

class SmoothCompositeImage < CompositeImage
  def initialize(list, outname, debug=true)
    @gaussians = {}
    @centered_gaussians = {}
    super(list, outname, debug)
  end

  def gaussian_ary(n)
    return @gaussians[n] if @gaussians[n]

    ary = (1..n).to_a.map do |i| 
      x = (6/n.to_f) * (i-n/2.to_f)
      Distribution::Normal.pdf(x) 
    end

    sum = ary.inject(:+)

    @gaussians[n] = ary.map { |i| i/sum }
  end

  def centered_gaussian_ary(n, center)
    return @centered_gaussians[center] if @centered_gaussians[center]

    sigmas = 5
    offset = (0.5 - center) * 2 * sigmas

    ary = (1..n).to_a.map do |i| 
      x = (sigmas*2/n.to_f) * (i - n/2.to_f) + offset
      Distribution::Normal.pdf(x) 
    end

    sum = ary.inject(:+)

    @centered_gaussians[center] = ary.map { |i| i/sum }
  end

  def max_radius
    @max_radius ||= Math.sqrt((height/2)**2 + (width/2)**2)
  end

  def concentric_circles_gaussian(x, y)
    r = Math.sqrt((height/2-x)**2 + (width/2-y)**2)
    centered_gaussian_ary(num, (r/max_radius.to_f).round(2))
  end

  def sine_grid_gaussian(x, y)
    size = 100
    centered_gaussian_ary(num, (Math.sin(x/size.to_f) + Math.sin(y/size.to_f) + 2)/4)
  end

  def horizontal_bands_gaussian(x, y)
    centered_gaussian_ary(num, (y/height.to_f).round(3))
  end

  def diagonal_bands_gaussian(x, y)
    centered_gaussian_ary(num, ((x+y)/width.to_f % 1).round(2))
  end

  def calculate_pixel(x, y, reds, greens, blues)
    gaussian = diagonal_bands_gaussian(x, y)

    [reds, greens, blues].map do |ary|
      ary.map.with_index do |value, i|
        value * gaussian[i]
      end.inject(:+).to_i
    end
  end
end