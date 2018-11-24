#!/usr/bin/env ruby
require 'sequel'
require 'json'

DB = Sequel.mysql2("bot0",
  user: ENV["BOT_USER"],
  password: ENV["BOT_PASSWORD"],
  host: 'localhost')
MSGS = DB[:msgs]
MSGS.each do |row|
  #puts row[:comment]
  puts JSON.parse(row[:msg])
end
