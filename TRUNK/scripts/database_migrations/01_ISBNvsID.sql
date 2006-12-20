alter TABLE checkouts alter column tomebook type int;
alter TABLE checkouts alter column semester type int;
ALTER TABLE tomebooks alter column expire type integer;

create table reservations (id serial primary key, isbn varchar(20) references books not null, uid int references users (id) not null, patron int references patrons (id) not null, reserved timestamp with time zone not null default now(), fulfilled timestamp with time zone, comment text, library_from int references libraries (id) not null, library_to int references libraries (id) not null, semester int references semesters (id) not null);

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
select count(*) from reservations where isbn = $1 AND library_to = $2 AND semester = $3 AND fulfilled IS NULL;
$$ LANGUAGE SQL;

CREATE FUNCTION reservation_update() RETURNS "trigger" AS $$
BEGIN
	IF(OLD.isbn IS DISTINCT FROM NEW.isbn OR OLD.library_to IS DISTINCT FROM NEW.library_to OR OLD.semester IS DISTINCT FROM NEW.semester) THEN
		raise exception 'Changing the isbn, library_to, or semester of a reservation is not allowed.';
	END IF;

	RETURN NEW;
end;
$$ Language plpgsql;

CREATE FUNCTION reservation_insert() RETURNS "trigger" AS $$
BEGIN
	IF tomebooks_reserved(NEW.isbn, NEW.library_to, NEW.semester) + 1 <= tomebooks_available_to_reserve(NEW.isbn, NEW.library_to, NEW.semester) THEN
		return NEW;
	else
		raise exception 'All available books are already reserved';
	end if;

	RETURN NEW;
end;
$$ Language plpgsql;

CREATE TRIGGER reservation_update BEFORE update on reservations for each row execute procedure reservation_update();
CREATE TRIGGER reservation_insert BEFORE insert on reservations for each row execute procedure reservation_insert();

CREATE FUNCTION checkouts_update() RETURNS "trigger" AS $$
BEGIN
	IF(OLD.tomebook IS DISTINCT FROM NEW.tomebook OR OLD.semester IS DISTINCT FROM NEW.semester OR OLD.library IS DISTINCT FROM NEW.library) THEN
		raise exception 'Changing the tomebook, semester, or library of a checkout is not allowed.';
	END IF;

	return NEW;
end;
$$ Language plpgsql;

CREATE FUNCTION checkouts_insert() RETURNS "trigger" AS $$
declare tomebook record;
BEGIN
	select into tomebook * from tomebooks where id = NEW.tomebook;
	IF tomebook.timeremoved IS NOT NULL THEN
		raise exception 'Cannot check out a tome book after it has been removed.';
	END IF;

	IF tomebooks_available_to_reserve(tomebook.isbn, tomebook.library, NEW.semester) - tomebooks_reserved(tomebook.isbn, tomebook.library, NEW.semester) < 1 THEN
		raise exception 'All available books are already reserved';
	end if;

	return NEW;
end;
$$ Language plpgsql;

CREATE TRIGGER checkouts_update BEFORE update on checkouts for each row execute procedure checkouts_update();
CREATE TRIGGER checkouts_insert BEFORE insert on checkouts for each row execute procedure checkouts_insert();

CREATE FUNCTION tomebooks_update() RETURNS "trigger" AS $$
declare semester_reservations record;
declare checkout record;
BEGIN
IF(NEW.timeremoved IS NOT NULL AND OLD.timeremoved IS NULL) THEN
	select into checkout * FROM checkouts where tomebook = NEW.id AND checkin IS NULL;
	if(FOUND) THEN
		raise exception 'Book cannot be removed while it is checked out.';
	END IF;

	FOR semester_reservations IN SELECT count(*) as count, semester from reservations where isbn = NEW.isbn AND fulfilled is null group by semester LOOP
		IF semester_reservations.count > (tomebooks_available_to_reserve(NEW.isbn, NEW.library, semester_reservations.semester) - 1) THEN
			raise exception 'Removing this book would invalidate a reservation';
		END IF;
	END LOOP;
END IF;
return NEW;
end;
$$ Language plpgsql;

CREATE TRIGGER tomebooks_update BEFORE update on tomebooks for each row execute procedure tomebooks_update();
