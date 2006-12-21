BEGIN WORK;
LOCK TABLE libraries;

alter table libraries add column intertome boolean not null default false;
update libraries set intertome = true;

COMMIT WORK;
