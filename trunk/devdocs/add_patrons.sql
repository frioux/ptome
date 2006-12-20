alter table users drop constraint usernameu;

create table patrons (id serial primary key, email text not null, name text not null);
create unique index upper_email_unique on patrons (upper(email));
insert into patrons (name, email) select distinct on (email) name, email FROM (select originator as name, lower(originator || '@replaceme.invalid') as email from tomebooks union select borrower as name, lower(borrower || '@replaceme.invalid') as email from checkouts) as sub;

alter table tomebooks add column originator_new integer;
update tomebooks set originator_new = (select id from patrons where name = originator);
ALTER TABLE tomebooks ADD constraint originator_fk foreign key (originator_new) references patrons (id);
update tomebooks set originator_new = select id from patrons where name = originator;
ALTER TABLE tomebooks ADD constraint originator_fk foreign key (originator_new) references patrons (id);
alter table tomebooks alter column originator_new set not null;
alter table tomebooks drop column originator;
alter table tomebooks rename column originator_new to originator;
