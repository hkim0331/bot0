#!/usr/bin/env ruby

require 'sequel'

DB = Sequel.mysql2("bot0",
  user: ENV["BOT_USER"],
  password: ENV["BOT_PASSWORD"],
  host: 'localhost')
MSGS = DB[:msgs]

Dir.glob("../messages/*.txt").each do |file|
  comment = File.basename(file).sub(/\.txt$/,'')
#  puts comment
  File.open(file) do |fp|
    MSGS.insert(comment: comment, msg: fp.readlines.join)
  end
end
