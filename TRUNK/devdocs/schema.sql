--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'Standard public schema';


--
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: 
--

CREATE PROCEDURAL LANGUAGE plpgsql;


SET search_path = public, pg_catalog;

--
-- Name: checkouts_insert(); Type: FUNCTION; Schema: public; Owner: tome_dev
--

CREATE FUNCTION checkouts_insert() RETURNS "trigger"
    AS $$
declare tomebook record;
declare library record;
BEGIN
select into tomebook * from tomebooks where id = NEW.tomebook;
IF tomebook.library != NEW.library THEN
select into library * from libraries where id = tomebook.library;
IF library.intertome is false THEN
raise exception 'Cannot make an InterTOME loan to a library that is not in the InterTOME system.';
end if;
select into library * from libraries where id = NEW.library;
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
$$
    LANGUAGE plpgsql;


--
-- Name: checkouts_update(); Type: FUNCTION; Schema: public; Owner: tome_dev
--

CREATE FUNCTION checkouts_update() RETURNS "trigger"
    AS $$
BEGIN
IF(OLD.tomebook IS DISTINCT FROM NEW.tomebook OR OLD.semester IS DISTINCT FROM NEW.semester OR OLD.library IS DISTINCT FROM NEW.library) THEN
raise exception 'Changing the tomebook, semester, or library of a checkout is not allowed.';
END IF;

return NEW;
end;
$$
    LANGUAGE plpgsql;


--
-- Name: isbn_force_upper(); Type: FUNCTION; Schema: public; Owner: tome_dev
--

CREATE FUNCTION isbn_force_upper() RETURNS "trigger"
    AS $$
begin
NEW.isbn := upper(NEW.isbn);
return NEW;
end;
$$
    LANGUAGE plpgsql;


--
-- Name: libraries_update(); Type: FUNCTION; Schema: public; Owner: tome_dev
--

CREATE FUNCTION libraries_update() RETURNS "trigger"
    AS $$
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
$$
    LANGUAGE plpgsql;


--
-- Name: reservation_insert(); Type: FUNCTION; Schema: public; Owner: tome_dev
--

CREATE FUNCTION reservation_insert() RETURNS "trigger"
    AS $$
declare library record;
BEGIN
IF NEW.library_from != NEW.library_to THEN
select into library * from libraries where id = NEW.library_to;
       IF library.intertome is false THEN
raise exception 'Cannot make InterTOME reservations to a library not in the InterTOME system.';
end if;
select into library * from libraries where id = NEW.library_from;
       IF library.intertome is false THEN
raise exception 'Cannot make InterTOME reservations from a library not in the InterTOME system.';
end if;
end if;

IF tomebooks_reserved(NEW.isbn, NEW.library_to, NEW.semester) + 1 <= tomebooks_available_to_reserve(NEW.isbn, NEW.library_to, NEW.semester) THEN
return NEW;
else
raise exception 'All available books are already reserved';
end if;

RETURN NEW;
end;
$$
    LANGUAGE plpgsql;


--
-- Name: reservation_update(); Type: FUNCTION; Schema: public; Owner: tome_dev
--

CREATE FUNCTION reservation_update() RETURNS "trigger"
    AS $$
BEGIN
IF(OLD.isbn IS DISTINCT FROM NEW.isbn OR OLD.library_to IS DISTINCT FROM NEW.library_to OR OLD.semester IS DISTINCT FROM NEW.semester) THEN
raise exception 'Changing the isbn, library_to, or semester of a reservation is not allowed.';
END IF;

RETURN NEW;
end;
$$
    LANGUAGE plpgsql;


--
-- Name: tomebooks_available_to_reserve(character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: tome_dev
--

CREATE FUNCTION tomebooks_available_to_reserve(character varying, integer, integer) RETURNS bigint
    AS $_$
select count(*) from tomebooks where library = $2 AND isbn = $1 AND timeremoved IS NULL AND id NOT IN (SELECT checkouts.tomebook FROM checkouts,tomebooks WHERE semester = $3 AND tomebooks.isbn = $1 AND checkin IS NULL AND tomebooks.library = $2 AND tomebooks.id = checkouts.tomebook);
$_$
    LANGUAGE sql;


--
-- Name: tomebooks_reserved(character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: tome_dev
--

CREATE FUNCTION tomebooks_reserved(character varying, integer, integer) RETURNS bigint
    AS $_$
select count(*) from reservations where isbn = $1 AND library_to = $2 AND semester = $3 AND fulfilled IS NULL;
$_$
    LANGUAGE sql;


--
-- Name: tomebooks_update(); Type: FUNCTION; Schema: public; Owner: tome_dev
--

CREATE FUNCTION tomebooks_update() RETURNS "trigger"
    AS $$
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
$$
    LANGUAGE plpgsql;


SET default_tablespace = '';

SET default_with_oids = true;

--
-- Name: books; Type: TABLE; Schema: public; Owner: tome_dev; Tablespace: 
--

CREATE TABLE books (
    isbn character varying(20) NOT NULL,
    title text NOT NULL,
    author text NOT NULL,
    edition text
);


--
-- Name: checkouts; Type: TABLE; Schema: public; Owner: tome_dev; Tablespace: 
--

CREATE TABLE checkouts (
    tomebook integer NOT NULL,
    semester integer NOT NULL,
    checkout timestamp with time zone DEFAULT now() NOT NULL,
    checkin timestamp with time zone,
    comments text,
    library integer NOT NULL,
    uid integer NOT NULL,
    id integer DEFAULT nextval(('public.checkouts_id_seq'::text)::regclass) NOT NULL,
    borrower integer NOT NULL,
    CONSTRAINT timeline CHECK (((checkin IS NULL) OR (checkin > checkout)))
);


--
-- Name: checkouts_id_seq; Type: SEQUENCE; Schema: public; Owner: tome_dev
--

CREATE SEQUENCE checkouts_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: classbooks; Type: TABLE; Schema: public; Owner: tome_dev; Tablespace: 
--

CREATE TABLE classbooks (
    "class" character varying(10) NOT NULL,
    isbn character varying(20) NOT NULL,
    verified smallint NOT NULL,
    comments text,
    usable boolean DEFAULT true NOT NULL,
    uid integer NOT NULL
);


--
-- Name: classes; Type: TABLE; Schema: public; Owner: tome_dev; Tablespace: 
--

CREATE TABLE classes (
    id text NOT NULL,
    name text NOT NULL,
    comments text,
    verified integer,
    uid integer
);


SET default_with_oids = false;

--
-- Name: db_version; Type: TABLE; Schema: public; Owner: tome_dev; Tablespace: 
--

CREATE TABLE db_version (
    version integer NOT NULL,
    "time" timestamp with time zone DEFAULT now() NOT NULL
);


SET default_with_oids = true;

--
-- Name: libraries; Type: TABLE; Schema: public; Owner: tome_dev; Tablespace: 
--

CREATE TABLE libraries (
    id serial NOT NULL,
    name text NOT NULL,
    intertome boolean DEFAULT false NOT NULL
);


--
-- Name: library_access; Type: TABLE; Schema: public; Owner: tome_dev; Tablespace: 
--

CREATE TABLE library_access (
    uid integer NOT NULL,
    library integer NOT NULL
);


SET default_with_oids = false;

--
-- Name: patron_classes; Type: TABLE; Schema: public; Owner: tome_dev; Tablespace: 
--

CREATE TABLE patron_classes (
    patron integer NOT NULL,
    semester integer NOT NULL,
    "class" text NOT NULL
);


SET default_with_oids = true;

--
-- Name: patrons; Type: TABLE; Schema: public; Owner: tome_dev; Tablespace: 
--

CREATE TABLE patrons (
    id serial NOT NULL,
    email text NOT NULL,
    name text NOT NULL
);


SET default_with_oids = false;

--
-- Name: reservations; Type: TABLE; Schema: public; Owner: tome_dev; Tablespace: 
--

CREATE TABLE reservations (
    id serial NOT NULL,
    isbn character varying(20) NOT NULL,
    uid integer NOT NULL,
    patron integer NOT NULL,
    reserved timestamp with time zone DEFAULT now() NOT NULL,
    fulfilled timestamp with time zone,
    "comment" text,
    library_from integer NOT NULL,
    library_to integer NOT NULL,
    semester integer NOT NULL,
    CONSTRAINT reservations_check CHECK (((fulfilled IS NULL) OR (fulfilled > reserved)))
);


SET default_with_oids = true;

--
-- Name: semesters; Type: TABLE; Schema: public; Owner: tome_dev; Tablespace: 
--

CREATE TABLE semesters (
    id serial NOT NULL,
    name text NOT NULL,
    current boolean DEFAULT false NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: tome_dev; Tablespace: 
--

CREATE TABLE sessions (
    id character(32) NOT NULL,
    a_session text NOT NULL
);


--
-- Name: tomebooks; Type: TABLE; Schema: public; Owner: tome_dev; Tablespace: 
--

CREATE TABLE tomebooks (
    id serial NOT NULL,
    isbn character varying(20) NOT NULL,
    expire integer,
    comments text,
    timedonated timestamp with time zone DEFAULT now() NOT NULL,
    library integer NOT NULL,
    timeremoved timestamp with time zone,
    originator integer NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: tome_dev; Tablespace: 
--

CREATE TABLE users (
    id serial NOT NULL,
    username text NOT NULL,
    email text NOT NULL,
    notifications boolean DEFAULT true NOT NULL,
    "admin" boolean DEFAULT false NOT NULL,
    "password" text NOT NULL,
    disabled boolean DEFAULT false NOT NULL
);


--
-- Name: books_pkey; Type: CONSTRAINT; Schema: public; Owner: tome_dev; Tablespace: 
--

ALTER TABLE ONLY books
    ADD CONSTRAINT books_pkey PRIMARY KEY (isbn);


--
-- Name: checkouts_pkey; Type: CONSTRAINT; Schema: public; Owner: tome_dev; Tablespace: 
--

ALTER TABLE ONLY checkouts
    ADD CONSTRAINT checkouts_pkey PRIMARY KEY (id);


--
-- Name: classbooks_pkey; Type: CONSTRAINT; Schema: public; Owner: tome_dev; Tablespace: 
--

ALTER TABLE ONLY classbooks
    ADD CONSTRAINT classbooks_pkey PRIMARY KEY ("class", isbn);


--
-- Name: classes_pkey; Type: CONSTRAINT; Schema: public; Owner: tome_dev; Tablespace: 
--

ALTER TABLE ONLY classes
    ADD CONSTRAINT classes_pkey PRIMARY KEY (id);


--
-- Name: db_version_pkey; Type: CONSTRAINT; Schema: public; Owner: tome_dev; Tablespace: 
--

ALTER TABLE ONLY db_version
    ADD CONSTRAINT db_version_pkey PRIMARY KEY (version);


--
-- Name: libraries_pkey; Type: CONSTRAINT; Schema: public; Owner: tome_dev; Tablespace: 
--

ALTER TABLE ONLY libraries
    ADD CONSTRAINT libraries_pkey PRIMARY KEY (id);


--
-- Name: patron_classes_pkey; Type: CONSTRAINT; Schema: public; Owner: tome_dev; Tablespace: 
--

ALTER TABLE ONLY patron_classes
    ADD CONSTRAINT patron_classes_pkey PRIMARY KEY (patron, semester, "class");


--
-- Name: patrons_pkey; Type: CONSTRAINT; Schema: public; Owner: tome_dev; Tablespace: 
--

ALTER TABLE ONLY patrons
    ADD CONSTRAINT patrons_pkey PRIMARY KEY (id);


--
-- Name: reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: tome_dev; Tablespace: 
--

ALTER TABLE ONLY reservations
    ADD CONSTRAINT reservations_pkey PRIMARY KEY (id);


--
-- Name: semesters_pkey; Type: CONSTRAINT; Schema: public; Owner: tome_dev; Tablespace: 
--

ALTER TABLE ONLY semesters
    ADD CONSTRAINT semesters_pkey PRIMARY KEY (id);


--
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: tome_dev; Tablespace: 
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: tomebooks_pkey; Type: CONSTRAINT; Schema: public; Owner: tome_dev; Tablespace: 
--

ALTER TABLE ONLY tomebooks
    ADD CONSTRAINT tomebooks_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: tome_dev; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: one_borrower; Type: INDEX; Schema: public; Owner: tome_dev; Tablespace: 
--

CREATE UNIQUE INDEX one_borrower ON checkouts USING btree (tomebook) WHERE (checkin IS NULL);


--
-- Name: one_current; Type: INDEX; Schema: public; Owner: tome_dev; Tablespace: 
--

CREATE UNIQUE INDEX one_current ON semesters USING btree (current) WHERE (current = true);


--
-- Name: upper_email_unique; Type: INDEX; Schema: public; Owner: tome_dev; Tablespace: 
--

CREATE UNIQUE INDEX upper_email_unique ON patrons USING btree (upper(email));


--
-- Name: upper_isbn; Type: INDEX; Schema: public; Owner: tome_dev; Tablespace: 
--

CREATE UNIQUE INDEX upper_isbn ON books USING btree (upper((isbn)::text));


--
-- Name: upper_username; Type: INDEX; Schema: public; Owner: tome_dev; Tablespace: 
--

CREATE UNIQUE INDEX upper_username ON users USING btree (upper(username));


--
-- Name: checkouts_insert; Type: TRIGGER; Schema: public; Owner: tome_dev
--

CREATE TRIGGER checkouts_insert
    BEFORE INSERT ON checkouts
    FOR EACH ROW
    EXECUTE PROCEDURE checkouts_insert();


--
-- Name: checkouts_update; Type: TRIGGER; Schema: public; Owner: tome_dev
--

CREATE TRIGGER checkouts_update
    BEFORE UPDATE ON checkouts
    FOR EACH ROW
    EXECUTE PROCEDURE checkouts_update();


--
-- Name: isbn_force_upper; Type: TRIGGER; Schema: public; Owner: tome_dev
--

CREATE TRIGGER isbn_force_upper
    BEFORE INSERT OR UPDATE ON books
    FOR EACH ROW
    EXECUTE PROCEDURE isbn_force_upper();


--
-- Name: libraries_update; Type: TRIGGER; Schema: public; Owner: tome_dev
--

CREATE TRIGGER libraries_update
    BEFORE UPDATE ON libraries
    FOR EACH ROW
    EXECUTE PROCEDURE libraries_update();


--
-- Name: reservation_insert; Type: TRIGGER; Schema: public; Owner: tome_dev
--

CREATE TRIGGER reservation_insert
    BEFORE INSERT ON reservations
    FOR EACH ROW
    EXECUTE PROCEDURE reservation_insert();


--
-- Name: reservation_update; Type: TRIGGER; Schema: public; Owner: tome_dev
--

CREATE TRIGGER reservation_update
    BEFORE UPDATE ON reservations
    FOR EACH ROW
    EXECUTE PROCEDURE reservation_update();


--
-- Name: tomebooks_update; Type: TRIGGER; Schema: public; Owner: tome_dev
--

CREATE TRIGGER tomebooks_update
    BEFORE UPDATE ON tomebooks
    FOR EACH ROW
    EXECUTE PROCEDURE tomebooks_update();


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY tomebooks
    ADD CONSTRAINT "$1" FOREIGN KEY (isbn) REFERENCES books(isbn);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY library_access
    ADD CONSTRAINT "$1" FOREIGN KEY (uid) REFERENCES users(id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY checkouts
    ADD CONSTRAINT "$1" FOREIGN KEY (tomebook) REFERENCES tomebooks(id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY classbooks
    ADD CONSTRAINT "$1" FOREIGN KEY ("class") REFERENCES classes(id);


--
-- Name: $2; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY classbooks
    ADD CONSTRAINT "$2" FOREIGN KEY (isbn) REFERENCES books(isbn);


--
-- Name: $2; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY library_access
    ADD CONSTRAINT "$2" FOREIGN KEY (library) REFERENCES libraries(id);


--
-- Name: borrower_fk; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY checkouts
    ADD CONSTRAINT borrower_fk FOREIGN KEY (borrower) REFERENCES patrons(id);


--
-- Name: classes_uid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY classes
    ADD CONSTRAINT classes_uid_fkey FOREIGN KEY (uid) REFERENCES users(id);


--
-- Name: classes_verified_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY classes
    ADD CONSTRAINT classes_verified_fkey FOREIGN KEY (verified) REFERENCES semesters(id);


--
-- Name: expirefk; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY tomebooks
    ADD CONSTRAINT expirefk FOREIGN KEY (expire) REFERENCES semesters(id) MATCH FULL;


--
-- Name: libraryfk; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY tomebooks
    ADD CONSTRAINT libraryfk FOREIGN KEY (library) REFERENCES libraries(id) MATCH FULL;


--
-- Name: libraryfk; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY checkouts
    ADD CONSTRAINT libraryfk FOREIGN KEY (library) REFERENCES libraries(id) MATCH FULL;


--
-- Name: originator_fk; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY tomebooks
    ADD CONSTRAINT originator_fk FOREIGN KEY (originator) REFERENCES patrons(id);


--
-- Name: patron_classes_class_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY patron_classes
    ADD CONSTRAINT patron_classes_class_fkey FOREIGN KEY ("class") REFERENCES classes(id);


--
-- Name: patron_classes_patron_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY patron_classes
    ADD CONSTRAINT patron_classes_patron_fkey FOREIGN KEY (patron) REFERENCES patrons(id);


--
-- Name: patron_classes_semester_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY patron_classes
    ADD CONSTRAINT patron_classes_semester_fkey FOREIGN KEY (semester) REFERENCES semesters(id);


--
-- Name: reservations_isbn_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY reservations
    ADD CONSTRAINT reservations_isbn_fkey FOREIGN KEY (isbn) REFERENCES books(isbn);


--
-- Name: reservations_library_from_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY reservations
    ADD CONSTRAINT reservations_library_from_fkey FOREIGN KEY (library_from) REFERENCES libraries(id);


--
-- Name: reservations_library_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY reservations
    ADD CONSTRAINT reservations_library_to_fkey FOREIGN KEY (library_to) REFERENCES libraries(id);


--
-- Name: reservations_patron_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY reservations
    ADD CONSTRAINT reservations_patron_fkey FOREIGN KEY (patron) REFERENCES patrons(id);


--
-- Name: reservations_semester_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY reservations
    ADD CONSTRAINT reservations_semester_fkey FOREIGN KEY (semester) REFERENCES semesters(id);


--
-- Name: reservations_uid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY reservations
    ADD CONSTRAINT reservations_uid_fkey FOREIGN KEY (uid) REFERENCES users(id);


--
-- Name: semesterfk; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY checkouts
    ADD CONSTRAINT semesterfk FOREIGN KEY (semester) REFERENCES semesters(id) MATCH FULL;


--
-- Name: userfk; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY classbooks
    ADD CONSTRAINT userfk FOREIGN KEY (uid) REFERENCES users(id) MATCH FULL;


--
-- Name: userfk; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY checkouts
    ADD CONSTRAINT userfk FOREIGN KEY (uid) REFERENCES users(id) MATCH FULL;


--
-- Name: verifiedfk; Type: FK CONSTRAINT; Schema: public; Owner: tome_dev
--

ALTER TABLE ONLY classbooks
    ADD CONSTRAINT verifiedfk FOREIGN KEY (verified) REFERENCES semesters(id) MATCH FULL;


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--



INSERT INTO db_version (version) VALUES (1);
