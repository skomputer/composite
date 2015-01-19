require './composite_image_list.rb'
require './composite_animation.rb'
require 'pry'

if ARGV.count < 2
  print "usage: #{File.basename($0)} FORMULA OUTNAME INFILES\n"
  exit
end

list = CompositeImageList.new(ARGV[2..ARGV.count])
formula = Object.const_get(ARGV[0]).new
animation = CompositeAnimation.new(list, formula, ARGV[1])

animation.build_and_write_transition_frame([0, 1], 10, 0)

# (0..animation.num-2).to_a.each do |n|
#   animation.build_transition_frames([n, n+1], 10, true)
# end