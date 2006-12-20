BEGIN WORK;

lock table reservations;

drop function reservation_insert () cascade;

CREATE FUNCTION reservation_insert() RETURNS "trigger" AS $$
declare library record;
BEGIN
	select into library * from libraries where id = NEW.library_to;
	IF NEW.library_from != NEW.library_to AND library.intertome is false THEN
		raise exception 'Cannot make InterTOME reservations to a library not in the InterTOME system.';
	end if;

	IF tomebooks_reserved(NEW.isbn, NEW.library_to, NEW.semester) + 1 <= tomebooks_available_to_reserve(NEW.isbn, NEW.library_to, NEW.semester) THEN
		return NEW;
	else
		raise exception 'All available books are already reserved';
	end if;

	RETURN NEW;
end;
$$ Language plpgsql;

CREATE TRIGGER reservation_insert BEFORE insert on reservations for each row execute procedure reservation_insert();

drop function checkouts_insert() cascade;

CREATE FUNCTION checkouts_insert() RETURNS "trigger" AS $$
declare tomebook record;
declare library record;
BEGIN
	select into tomebook * from tomebooks where id = NEW.tomebook;
	IF tomebook.library != NEW.library THEN
		select into library * from libraries where id = tomebook.library;
		IF library.intertome is false THEN
			raise exception 'Cannot make an InterTOME loan from a library that is not in the InterTOME system.';
		end if;
	end if;

	IF tomebook.timeremoved IS NOT NULL THEN
		raise exception 'Cannot check out a tome book after it has been removed.';
	END IF;

	IF tomebooks_available_to_reserve(tomebook.isbn, tomebook.library, NEW.semester) - tomebooks_reserved(tomebook.isbn, tomebook.library, NEW.semester) < 1 THEN
		raise exception 'All available books are already reserved';
	end if;

	return NEW;
end;
$$ Language plpgsql;

CREATE TRIGGER checkouts_insert BEFORE insert on checkouts for each row execute procedure checkouts_insert();

COMMIT WORK;
