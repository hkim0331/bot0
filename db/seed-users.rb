#!/usr/bin/env ruby

require 'sequel'

DB = Sequel.mysql2("bot0",
  user: ENV["BOT_USER"],
  password: ENV["BOT_PASSWORD"],
  host: 'localhost')
USERS = DB[:users]

File.foreach("users.txt") do |line|
  name, uid = line.chomp.split
  USERS.insert(name: name, uid: uid)
  puts "insert #{line}"
end
