DB=bot0.sqlite3

shotgun:
	shotgun bot0.rb 

stop:
	kill `ps ax | grep 'ruby bot0' | awk '{print $$1}'`

create:
	sqlite3 ${DB} < create.sql

dump:
	echo ".dump" | sqlite3 ${DB} > sqlite3.dump

create-mysql:
	mysql -u root -p < create-mysql.sql
#	make mysql-seed

#mysql-seed:
#	mysql -u root -p bot0 < sqlite3.dump

