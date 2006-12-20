alter TABLE checkouts alter column tomebook type int;
alter TABLE checkouts alter column semester type int;
ALTER TABLE tomebooks alter column expire type integer;

create table reservations (id serial primary key, isbn varchar(20) references books not null, uid int references users (id) not null, patron int references patrons (id) not null, reserved timestamp with time zone not null default now(), fulfilled timestamp with time zone, comment text, library_from int references libraries (id) not null, library_to int references libraries (id), semester int references semesters (id) not null);

insert into reservations (isbn,uid,patron,reserved,comment,library_from, library_to,semester) select isbn, uid, borrower as patron, checkout as reserved, checkouts.comments as comment, checkouts.library as library_from, tomebooks.library as library_to, semester from checkouts,tomebooks where reservation = true AND checkouts.tomebook = tomebooks.id;

delete from checkouts where reservation = true;
drop INDEX one_borrower;
drop INDEX one_reservation;
alter table checkouts drop constraint checkout_or_reservation;
ALTER TABLE checkouts drop column reservation;
CREATE UNIQUE INDEX one_borrower ON checkouts (tomebook) WHERE checkin IS NULL;
ALTER TABLE reservations ADD check(fulfilled IS NULL OR fulfilled > reserved);

create function tomebooks_available_to_reserve(books.isbn%TYPE, tomebooks.library%TYPE, checkouts.semester%TYPE) returns bigint AS $$
select count(*) from tomebooks where library = $2 AND isbn = $1 AND timeremoved IS NULL AND id NOT IN (SELECT checkouts.tomebook FROM checkouts,tomebooks WHERE semester = $3 AND tomebooks.isbn = $1 AND checkin IS NULL AND tomebooks.library = $2 AND tomebooks.id = checkouts.tomebook);
$$ LANGUAGE SQL;

create function tomebooks_reserved(books.isbn%TYPE, tomebooks.library%TYPE, checkouts.semester%TYPE) returns bigint AS $$
select count(*) from reservations where isbn = $1 AND library_to = $2 AND semester = $3;
$$ LANGUAGE SQL;
