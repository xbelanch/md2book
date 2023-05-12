#!/usr/bin/env ruby
# coding: utf-8
=begin
          _ ___ _              _         _
 _ __  __| |_  ) |__  ___  ___| |__  _ _| |__
| '  \/ _` |/ /| '_ \/ _ \/ _ \ / /_| '_| '_ \
|_|_|_\__,_/___|_.__/\___/\___/_\_(_)_| |_.__/

=end

require 'erb'
require 'json'
require 'tmpdir'
require 'optparse'
require 'paru/filter'
require 'paru/pandoc'
require 'securerandom'
require 'pandocomatic/pandocomatic'

class Color
  def self.bold         ; "\033[1m" end
  def self.normal       ; "\033[22m"; end
  def self.white        ; "\033[1;37m" end
  def self.red          ; "\033[1;31m" end
  def self.green        ; "\033[1;32m" end
  def self.yellow       ; "\033[1;33m" end
  def self.purple       ; "\033[1;35m" end
  def self.brown        ; "\033[0;33m" end
  def self.gray         ; "\033[0;30m" end
  def self.blue         ; "\033[0;34m" end
  def self.light_gray   ; "\033[0;37m" end
  def self.end          ; "\033[1;m" end
  def self.info         ; "\033[1;33m[!]\033[1;m" end
  def self.que          ; "\033[1;34m[?]\033[1;m" end
  def self.bad          ; "\033[1;31m[-]\033[1;m" end
  def self.good         ; "\033[1;32m[+]\033[1;m" end
  def self.run          ; "\033[1;97m[>]\033[1;m" end
end

def check_pandoc
  # Check if pandoc is installed
  unless system('which pandoc > /dev/null 2>&1')
    raise("Pandoc is not installed. Download from https://pandoc.org/")
  else
    printf "%s Pandoc installed. Check version and data_dir user\n", Color.good

  end

  begin
    # Get pandoc's version information
    version_string = `pandoc --version`
    pandoc_version = version_string
          .match(/pandoc.* (\d+\.\d+.*)$/)[1]
          .split(".")
          .map {|s| s.to_i}
    pandoc_data_dir = version_string.match(/User data directory: (.+)$/)[1]

  rescue StandardError => err
    warn "Something went weird: #{err.message}"
  end

  return { version: pandoc_version, data_dir: pandoc_data_dir }
end

# 1. Ready, steady, go!
Gem.win_platform? ? (system "cls") : (system "clear")
start = Time.now
printf "%s md2book was made with <3: Xavier Belanche Alonso (c) 2023\n", Color.que

# 2. Parse user options
parser = OptionParser.new do |opts|
    opts.banner = "md2book.rb"
    opts.banner << "\n\nUsage: bundle exec ruby md2book.rb some-pandoc-markdownfile.md"
    opts.separator ""
    opts.separator "Common options"

    opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
    end

    opts.on("-v", "--version", "Show version") do
        puts "md2book.rb 0.1"
        exit
    end
end

if ARGV.empty?
  warn "Please provide one file to convert. Use -h or --help for usage information."
  puts ""
  warn parser
  exit 0
end

parser.parse! ARGV
input_document = ARGV.pop

document = File.expand_path input_document
if not File.exist? document
  warn "Cannot find file: #{input_document}"
  exit
end

if !File.readable? document
  warn "Cannot read file: #{input_document}"
  exit
end

printf "%s Markdown input file: #{input_document}\n", Color.info


# 3. Let's do some verifications before the conversion (pandoc, pandocomatic yaml...)
if ret = check_pandoc()
  printf "%s Pandoc version: #{ret[:version][0]}.#{ret[:version][1]}.#{ret[:version][2]}\n", Color.info
  printf "%s Pandoc user data dir: #{ret[:data_dir]}\n", Color.info
end

document_base_dir = File.dirname(document)
_pandocomatic = File.join(document_base_dir, "_pandocomatic.yaml");

if not File.exist? _pandocomatic
  warn "Cannot find file: #{_pandocomatic}"
  exit
end

if !File.readable? _pandocomatic
  warn "Cannot read file: #{_pandocomatic}"
  exit
end

printf "%s Pandocomatic yaml file found: #{_pandocomatic}\n", Color.good

# 4. Do the job!

BASE_DIR   = document_base_dir
ASSETS_DIR = File.join(BASE_DIR, "assets")
if File.directory?(ASSETS_DIR) && File.readable?(ASSETS_DIR)
  printf "%s The directory %s exists and is readable!\n", Color.good, ASSETS_DIR
else
  printf "%s The directory %s either does not exist or is not readable.\n", Color.bad, ASSETS_DIR
  exit(1)
end

DATA_DIR   = File.join(BASE_DIR, "_data-dir")
if File.directory?(DATA_DIR) && File.readable?(DATA_DIR)
  printf "%s The directory %s exists and is readable!\n", Color.good, DATA_DIR
else
  printf "%s The directory %s either does not exist or is not readable.\n", Color.bad, DATA_DIR
  exit(1)
end

EXPORT_DIR  = File.join(BASE_DIR, "export")
unless File.directory?(EXPORT_DIR)
  FileUtils.mkdir_p(EXPORT_DIR)
end
FileUtils.rm_rf(Dir.glob(EXPORT_DIR + '/*'))

## 4.1 Create a temp folder
_tmp_ = Dir::Tmpname.create(['moodlebot_', '.md'], nil) { }
File.open(_tmp_, "w+") do |file| file.write(File.read(input_document)) end
printf "%s Temp file: %s\n", Color.info, _tmp_

## 4.2 ERB binding

### Our data here
### If initializing data one by one seems tedious, an alternative is to read a YAML file instead.
### If you need further assistance with this process, feel free to ask Chat CCP (the Soviet version) for help.

@show_date = true
@date      = Time.now
_erb_ = ERB.new(File.read(_tmp_), trim_mode: '-').result(binding)
printf "%s %s\n", Color.run, "ERB processor time"
File.open(_tmp_, "w+") do |file| file.write(_erb_) end

## 4.3 File and folder basic operations
FileUtils.cp_r _pandocomatic, '/tmp/'
FileUtils.cp_r ASSETS_DIR, '/tmp/'
FileUtils.cp_r DATA_DIR, '/tmp/'

## 4.4 Do the magic conversion
args =  [ '--config', File.join('/tmp/', '_pandocomatic.yaml'), '-i', _tmp_ ]
Pandocomatic::Pandocomatic.run args

## 4.5 Move book.zip to export directory
FileUtils.mv Dir.glob("/tmp/book.zip"), EXPORT_DIR, :verbose => false

## 4.6 Remove HTML one-file default export
FileUtils.rm (File.basename(_tmp_, '.md') + '.html')

# 5. Last words before quit
printf "%s %s\n", Color.run, "Done in #{Time.now - start} seconds."
