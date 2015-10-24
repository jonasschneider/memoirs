require "rubygems"
require "bundler/setup"

$:.unshift '.'
require 'memoirs'

task :annotate do
  loop do
    mem = DB[:memoirs].where(subtext:nil).where('category_id IN (1,3)').order(Sequel.lit('RANDOM()')).first
    subtext = nil
    Tempfile.open 'memoir-annotate' do |f|
      f.write("\n_____\n#{mem[:body]}\n")
      f.flush
      f.rewind
      sh ENV["EDITOR"], f.path
      subtext = File.read(f.path).split("_____").first
    end

    break if subtext.strip == "x"
    next if subtext.strip.empty?

    puts "for #{mem[:id]}: '#{subtext}'"
    DB[:memoirs].where(id:mem[:id]).update(subtext: subtext)
  end
end
