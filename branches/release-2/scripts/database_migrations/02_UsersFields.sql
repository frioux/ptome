--function to check and update database version
CREATE OR REPLACE FUNCTION check_and_update_dbversion(integer, integer) RETURNS integer AS $$
DECLARE
  old_version ALIAS FOR $1;
  new_version ALIAS FOR $2;
  cur_version integer;
BEGIN
--check
SELECT max(version) INTO cur_version FROM db_version;
IF cur_version != old_version THEN
  RAISE EXCEPTION 'WRONG DB VERSION: %. Exiting.', cur_version;
END IF;
--update
INSERT INTO db_version (version) VALUES(new_version);
RETURN 0;
END;
$$ LANGUAGE plpgsql;


BEGIN WORK;
--check & update database version first
SELECT check_and_update_dbversion(1, 2);
--add fields to users table
LOCK TABLE users;
ALTER TABLE users ADD COLUMN first_name TEXT;
ALTER TABLE users ADD COLUMN last_name TEXT;
ALTER TABLE users ADD COLUMN second_contact TEXT;
ALTER TABLE users ADD COLUMN has_logged_in BOOLEAN NOT NULL DEFAULT FALSE;
--set all default values for current tomekeepers
UPDATE users SET first_name = 'firstname';
UPDATE users SET last_name = 'lastname';
--now set not null constraints
ALTER TABLE users ALTER COLUMN first_name SET NOT NULL;
ALTER TABLE users ALTER COLUMN last_name SET NOT NULL;

COMMIT WORK;
