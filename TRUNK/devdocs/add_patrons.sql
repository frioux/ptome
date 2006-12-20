alter table users drop constraint usernameu;

create table patrons (id serial primary key, email text not null, name text not null);
create unique index upper_email_unique on patrons (upper(email));

alter table tomebooks add column originator_new integer;
ALTER TABLE tomebooks ADD constraint originator_fk foreign key (originator_new) references patrons (id);

alter table checkouts add column borrower_new integer;
alter table checkouts add constraint borrower_fk foreign key (borrower_new) references patrons (id);

# put the new stuff in

alter table tomebooks alter column originator_new set not null;
alter table tomebooks drop column originator;
alter table tomebooks rename column originator_new to originator;

alter table checkouts alter column borrower_new set not null;
alter table checkouts drop column borrower;
alter table checkouts rename column borrower_new to borrower;
