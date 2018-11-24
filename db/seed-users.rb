#!/usr/bin/env ruby

require 'sequel'

USERS = Sequel.mysql2("bot0", user: 'user', password: 'password', host: 'localhost')[:USERS]

File.foreach("users.txt") do |line|
  name, uid = line.chomp.split
  USERS.insert(name: name, uid: uid)
  puts "insert #{line}"
end
