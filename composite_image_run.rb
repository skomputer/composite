require './composite_image_list.rb'
require './composite_image.rb'
require 'pry'

if ARGV.count < 2
  print "usage: #{File.basename($0)} CLASSNAME OUTNAME INFILES\n"
  exit
end

list = CompositeImageList.new(ARGV[2..ARGV.count])
list.remove_horizontal_inputs

composite = Object.const_get(ARGV[0]).new(list, ARGV[1])
composite.build_output_image
composite.write_output_image