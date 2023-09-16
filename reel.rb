#!/usr/bin/env ruby

require 'optparse'
require 'csv'
require 'fileutils'

# Function to display usage information
def usage
  puts "Usage: ruby split_video.rb [options] SOURCE_VIDEO"
  puts "    -c, --clips CLIPS_FILE         Specify the CSV file containing clip information (default: stdin)"
  puts "    -d, --destination-folder FOLDER Specify the destination folder for the output clips"
  puts "    -v, --verbose LEVEL            Set verbose level (default: 0)"
  puts "    -h, --help                     Display this help message"
end

# Function to convert time (HH:MM:SS or MM:SS or SS) to total seconds
def time_to_seconds(time_str)
  units = time_str.split(':').map(&:to_i).reverse
  units.each_with_index.reduce(0) do |acc, (unit, idx)|
    acc + (unit * (60 ** idx))
  end
end

# Function to split video
def split_video(input_video, clips_data, destination_folder, verbose)
  clips_data.each do |row|
    start_time, end_time, output_name = row
    start_seconds = time_to_seconds(start_time)
    end_seconds = time_to_seconds(end_time)
    duration = end_seconds - start_seconds

    output_path = File.join(destination_folder, "#{output_name}.mp4")
    cmd = "ffmpeg -ss #{start_time} -t #{duration} -i #{input_video} -c copy #{output_path}"

    if verbose <= 2
      cmd += " -loglevel quiet"
    end

    system(cmd)

    puts "✅ Generated clip: #{output_path}" if verbose >= 1
    puts "🔨 FFmpeg Command: #{cmd}" if verbose >= 2
  end

  puts "✅ Video splitting complete." if verbose >= 1
end

# Command-line options
options = { verbose: 0 }
OptionParser.new do |opts|
  opts.banner = "Usage: split_video.rb [options]"

  opts.on("-c", "--clips CLIPS_FILE", "Specify the CSV file containing clip information") do |v|
    options[:clips] = v
  end

  opts.on("-d", "--destination-folder FOLDER", "Specify the destination folder for output clips") do |v|
    options[:destination_folder] = v
  end

  opts.on("-v", "--verbose LEVEL", Integer, "Set verbose level (default: 0)") do |v|
    options[:verbose] = v
  end

  opts.on("-h", "--help", "Prints this help") do
    usage
    exit
  end
end.parse!

# Get source video from ARGV
source_video = ARGV[0]

if source_video.nil?
  usage
  exit 1
end

# Check destination folder
destination_folder = options[:destination_folder] || "."
unless Dir.exist?(destination_folder)
  puts "🚨 Specified destination folder does not exist."
  exit 1
end

# Read clip information
clips_data = if options[:clips]
  unless File.exist?(options[:clips])
    puts "🚨 Specified clips file does not exist."
    exit 1
  end
  CSV.read(options[:clips])
else
  # Read from stdin if no file specified
  STDIN.readlines.map { |line| line.strip.split(",") }
end

# Perform the video splitting
split_video(source_video, clips_data, destination_folder, options[:verbose])