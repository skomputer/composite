require 'rmagick'

class CompositeAnimation
  def initialize(list, formula, outname, debug=true)
    @input_list = list
    @formula = formula
    @outname = outname
    @debug = true
    @output_images = []
  end

  def log(*strs)
    print(*strs) if @debug
  end

  def images
    @input_list.images.to_a
  end

  def images_by_indexes(indexes)
    indexes.map { |i| images[i] }
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
  
  def clear_frames
    @output_images = []
  end

  def suffix_from_indexes(indexes)
    str = "-" + indexes.join("-")
  end

  def build_transition_frames(image_indexes, num_frames = 10, write = false)
    log "\nbuilding frames for images #{image_indexes.join(', ')}\n"

    clear_frames
    suffix = suffix_from_indexes(image_indexes)

    (0..num_frames-1).to_a.each do |i|
      log "\nbuilding frame #{i}\n"
      image = build_transition_frame(image_indexes, num_frames, i)
      write_frame(image, i, suffix) if write
    end
  end  

  def build_transition_frame(image_indexes, num_frames, i)
    image = Magick::Image.constitute(width, height, "RGB", transition_frame_data(image_indexes, i/num_frames.to_f))
    @output_images << image
    image
  end

  def build_and_write_transition_frame(image_indexes, num_frames, i)
    suffix = suffix_from_indexes(image_indexes)
    image = build_transition_frame(image_indexes, num_frames, i)
    write_frame(image, i, suffix)
  end

  def transition_frame_data(image_indexes, percent)
    imgs = images_by_indexes(image_indexes)

    (0..height-1).to_a.map do |y|
      log "\rbuilding row #{y+1} out of #{height}..."      
      imgs.map do |image| 
        image.dispatch(0, y, width, 1, "RGB")
      end.transpose.each_slice(3).map.with_index do |data, x| 
        @formula.calculate_pixel(x, y, percent, *data)
      end
    end.flatten
  end

  def write_frames(suffix = nil)
    @output_images.each_with_index do |image, i|
      write_frame(image, i, suffix)
    end
  end

  def write_frame(image, i, suffix = nil)
    image.write(frame_name(i, suffix))
  end

  def frame_name(i, suffix = nil)
    dir = File.dirname(@outname)
    ext = File.extname(@outname)
    base = File.basename(@outname, ext) + suffix
    "#{dir}/#{base}-#{i}#{ext}"
  end
end


class CompositeAnimationFormula
  def calculate_pixel(x, y, percent, reds, greens, blues)
    throw "calculate_pixel not defined"
  end

  def intensity(r, g, b)
    (0.299*r + 0.587*g + 0.114*b)/Magick::QuantumRange
  end
end


class SecondFillsFirst < CompositeAnimationFormula
  def initialize
    @front_channel = :front
    @back_channel = :back
    @buffer = 1
  end
  
  def calculate_pixel(x, y, percent, reds, greens, blues)
    return [reds[0], greens[0], blues[0]] if percent.round(2) == 0.00
    return [reds[1], greens[1], blues[1]] if percent.round(2) == 1.00

    return intensity(reds[0], greens[0], blues[0]) > percent \
      ? [reds[0], greens[0], blues[0]] \
      : [reds[1], greens[1], blues[1]]
  end
end