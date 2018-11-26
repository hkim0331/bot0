drop tabe if exists msgs;
create table msgs (
id	integer primary key not null auto_increment,
comment varchar(255) default "",
msg text,
timestamp TIMESTAMP);

