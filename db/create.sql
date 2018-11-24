drop table if exists data;
create table data(
       id     integer primary key autoincrement,
       name   varchar(30),
       hb     int,
       timestamp TIMESTAMP
       );
