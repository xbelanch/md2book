#!/usr/bin/env ruby
# coding: utf-8
require "paru/filter"
require "zip"

BASE_DIR          = File.absolute_path(".")
DATA_DIR          = File.join(BASE_DIR, "_data-dir")
BOOK_TEMPLATE_DIR = File.join(DATA_DIR, "templates")
files = Dir.entries(BOOK_TEMPLATE_DIR)
# Iterate over each file
files.each do |file|
  # Skip '.' and '..' directories
  next if file == '.' || file == '..'
  warn file
end
BOOK_ASSETS_DIR   = File.join(BASE_DIR, "assets")
EXPORT_DIR        = File.join(BASE_DIR, "book")

# Define our html filter
module Paru
  module PandocFilter
    AST2HTML = Paru::Pandoc.new do
      from "json"
      to "html"
      standalone
      quiet
      data_dir DATA_DIR
      template File.join(BOOK_TEMPLATE_DIR, "book.html")
    end
  end
end

def titleize(header)
  accents = {  ['á','à','â','ä','ã'] => 'a', ['Ã','Ä','Â','À'] => 'a', ['é','è','ê','ë'] => 'e',['Ë','É','È','Ê'] => 'e', ['í','ì','î','ï'] => 'i', ['Î','Ì','Í'] => 'i', ['ó','ò','ô','ö','õ'] => 'o',  ['Õ','Ö','Ô','Ò','Ó'] => 'o', ['ú','ù','û','ü'] => 'u', ['Ú','Û','Ù','Ü'] => 'u', ['ç'] => 'c', ['Ç'] => 'c', ['ñ'] => 'ny', ['Ñ'] => 'ny' }
  accents.each do |ac,rep|
    ac.each do |s|
      header.inner_markdown = header.inner_markdown.gsub(s, rep)
    end
  end
  header.inner_markdown.gsub(" ", "_").strip
end

def new_document()
    Paru::PandocFilter::Document.new Paru::PandocFilter::CURRENT_PANDOC_VERSION, [], []
end

# Main filter
chapters = {}
moodlebook = []
doc = new_document

FileUtils.rm_r         EXPORT_DIR, :force=>true if File.directory?(EXPORT_DIR)
FileUtils::mkdir_p     EXPORT_DIR
FileUtils.cp_r         BOOK_ASSETS_DIR, EXPORT_DIR
FileUtils.cp_r         Dir.glob(File.join(BOOK_TEMPLATE_DIR, '*.css')), EXPORT_DIR

Paru::Filter.run do
  with "Header" do |header|
    page = Hash.new
    if header.has_class?("chapter")|| header.has_class?("subchapter")
      doc = new_document
      page[:content] = doc
      page[:isChapter] = true if header.level == 1
      page[:isSubchapter] = true if header.level == 2
      page[:header] = header
      metadata['pagetitle'] = header.inner_markdown.strip
      metadata['css'] = "book.css"
      page[:content].meta = metadata.to_meta
      moodlebook.push page
    end
  end
  if @ran_before
    doc << current_node if current_node.parent.is_a? Paru::PandocFilter::Document
  end
end

moodlebook.each_with_index do |doc, index|
  filename = File.join(EXPORT_DIR, "#{index+1}.html") if doc[:isChapter]
  filename = File.join(EXPORT_DIR, "#{index+1}_sub.html") if doc[:isSubchapter]
  Paru::PandocFilter::AST2HTML.configure do
    output filename
  end << doc[:content].to_JSON
end

new = File.join(File.dirname(EXPORT_DIR), File.basename(EXPORT_DIR)) + '.zip'
FileUtils.rm new, force: true
Zip::File.open(new, Zip::File::CREATE) do | zipfile |
  Dir["#{EXPORT_DIR}/**/**"].map{|e|e.sub %r[^#{EXPORT_DIR}/],''}.reject{|f|f==new}.each do | item |
    zipfile.add(item, File.join(EXPORT_DIR, item))
  end
end
