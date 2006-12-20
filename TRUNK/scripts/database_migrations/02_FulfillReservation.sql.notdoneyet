BEGIN WORK;

lock table db_version;

CREATE FUNCTION reservation_fulfill(reservations.id%TYPE, tomebooks.id%TYPE) RETURNS bigint AS $$
BEGIN;
LOCK TABLE reservations, checkouts;
UPDATE reservations SET fulfilled = now() WHERE id = $1;
INSERT INTO checkouts (tomebook, semester, comments, library, uid, borrower) SELECT $2 as tomebook, reservations.semester, reservations.comment as comments, reservations.library_from as library, reservations.uid, reservations.patron as borrower FROM reservations, tomebooks WHERE reservations.id = $1 AND tomebooks.id = $2 AND tomebooks.isbn = reservations.isbn;
COMMIT;
select currval('checkouts_id_seq');
$$ LANGUAGE SQL;

insert into db_version (version) values (2);

COMMIT WORK;
