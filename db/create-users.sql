drop table if exists users;
create table users (
id integer not null primary key auto_increment,
name varchar(255) default "",
uid varchar(255) default "",
timestamp TIMESTAMP);

