BEGIN WORK;
LOCK TABLE libraries;

CREATE FUNCTION libraries_update() RETURNS "trigger" AS $$
declare reservation_count record;
BEGIN
	IF OLD.intertome = TRUE AND NEW.intertome = FALSE THEN
		select into reservation_count count(*) as count from reservations where library_to = NEW.id and fulfilled is null;
		IF reservation_count.count > 0 THEN
			raise exception 'Cannot remove this library from InterTOME until it has no pending reservations';
		END IF;
	end if;

	return NEW;
end;
$$ Language plpgsql;

create trigger libraries_update BEFORE update on libraries for each row execute procedure libraries_update();

COMMIT WORK;
