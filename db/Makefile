all: msgs users

create-msgs:
	mysql -u user -p bot0 < create-msgs.sql

create-users:
	mysql -u user -p bot0 < create-users.sql

msgs: create-msgs
	ruby seed-msgs.rb

users: create-users
	ruby seed-users.rb
