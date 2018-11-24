#!/usr/bin/env ruby

require 'sequel'
MSGS = Sequel.mysql2("bot0", user: 'user', password: 'password', host: 'localhost')[:MSGS]

Dir.glob("../messages/*.txt").each do |file|
  comment = File.basename(file).sub(/\.txt$/,'')
#  puts comment
  File.open(file) do |fp|
    MSGS.insert(comment: comment, msg: fp.readlines.join)
  end
end
