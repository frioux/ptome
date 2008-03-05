BEGIN WORK;
--**this transaction will fail if there are tomekeepers with no library permissions in library_access

--check & update database to version 3
SELECT check_and_update_dbversion(2,3);

--create function to get a library id from libraries table & set in users table for that user
CREATE OR REPLACE FUNCTION set_primary_libraries() RETURNS integer AS $$
DECLARE
user_rec RECORD;
library_access_rec RECORD;
BEGIN
--for each tomekeeper
FOR user_rec IN SELECT * FROM users LOOP
  --get a library that he has access to (from library access table)
  SELECT INTO library_access_rec * FROM library_access WHERE uid=user_rec.id;
  RAISE NOTICE 'primary library = %', library_access_rec.library;
  --set that library in the users table (primary_library)
  UPDATE users SET primary_library=library_access_rec.library WHERE id=user_rec.id;
END LOOP;
RETURN 0;
END;
$$ LANGUAGE plpgsql;

--lock table & make changes
LOCK TABLE users;
ALTER TABLE users ADD COLUMN primary_library integer;
--set library for each user
SELECT set_primary_libraries();
--now set checks on primary_library column
ALTER TABLE users ALTER COLUMN primary_library SET NOT NULL;
ALTER TABLE users ADD CONSTRAINT primary_library_fk FOREIGN KEY (primary_library) REFERENCES libraries(id) MATCH FULL;

COMMIT WORK;
