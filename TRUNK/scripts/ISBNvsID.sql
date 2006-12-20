create table reservations (id serial primary key, isbn varchar(20) references books not null, uid int references users (id) not null, patron int references patrons (id) not null, reserved timestamp with time zone not null default now(), fulfilled timestamp with time zone, comment text, library int references libraries (id) not null, semester int references semesters (id) not null);

insert into reservations (isbn,uid,patron,reserved,comment,library,semester) select isbn, uid, borrower as patron, checkout as reserved, checkouts.comments as comment, checkouts.library as library, semester from checkouts,tomebooks where reservation = true AND checkouts.tomebook = tomebooks.id;

delete from checkouts where reservation = true;
drop INDEX one_borrower;
drop INDEX one_reservation;
alter table checkouts drop constraint checkout_or_reservation;
ALTER TABLE checkouts drop column reservation;
CREATE UNIQUE INDEX one_borrower ON checkouts (tomebook) WHERE checkin IS NULL;
ALTER TABLE reservations ADD check(fulfilled IS NULL OR fulfilled > reserved);

