drop database if exists bot0;
create database bot0;
use bot0;

drop table if exists data;
create table data (
       id     integer primary key auto_increment,
       name   varchar(30),
       hb     int,
       timestamp TIMESTAMP
);
