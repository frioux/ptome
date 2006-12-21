create table db_version (version int primary key, time timestamp with time zone default now() not null);
insert into db_version (version) values (1);
