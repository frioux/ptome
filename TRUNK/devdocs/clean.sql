--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

ALTER TABLE ONLY public.classbooks DROP CONSTRAINT verifiedfk;
ALTER TABLE ONLY public.checkouts DROP CONSTRAINT userfk;
ALTER TABLE ONLY public.classbooks DROP CONSTRAINT userfk;
ALTER TABLE ONLY public.checkouts DROP CONSTRAINT semesterfk;
ALTER TABLE ONLY public.tomebooks DROP CONSTRAINT originator_fk;
ALTER TABLE ONLY public.checkouts DROP CONSTRAINT libraryfk;
ALTER TABLE ONLY public.tomebooks DROP CONSTRAINT libraryfk;
ALTER TABLE ONLY public.tomebooks DROP CONSTRAINT expirefk;
ALTER TABLE ONLY public.checkouts DROP CONSTRAINT borrower_fk;
ALTER TABLE ONLY public.library_access DROP CONSTRAINT "$2";
ALTER TABLE ONLY public.classbooks DROP CONSTRAINT "$2";
ALTER TABLE ONLY public.library_access DROP CONSTRAINT "$1";
ALTER TABLE ONLY public.classbooks DROP CONSTRAINT "$1";
ALTER TABLE ONLY public.checkouts DROP CONSTRAINT "$1";
ALTER TABLE ONLY public.tomebooks DROP CONSTRAINT "$1";
DROP TRIGGER isbn_force_upper ON public.books;
DROP INDEX public.upper_username;
DROP INDEX public.upper_isbn;
DROP INDEX public.upper_email_unique;
DROP INDEX public.one_reservation;
DROP INDEX public.one_current;
DROP INDEX public.one_borrower;
ALTER TABLE ONLY public.users DROP CONSTRAINT users_pkey;
ALTER TABLE ONLY public.tomebooks DROP CONSTRAINT tomebooks_pkey;
ALTER TABLE ONLY public.sessions DROP CONSTRAINT sessions_pkey;
ALTER TABLE ONLY public.semesters DROP CONSTRAINT semesters_pkey;
ALTER TABLE ONLY public.patrons DROP CONSTRAINT patrons_pkey;
ALTER TABLE ONLY public.libraries DROP CONSTRAINT libraries_pkey;
ALTER TABLE ONLY public.classes DROP CONSTRAINT classes_pkey;
ALTER TABLE ONLY public.classbooks DROP CONSTRAINT classbooks_pkey;
ALTER TABLE ONLY public.checkouts DROP CONSTRAINT checkouts_pkey;
ALTER TABLE ONLY public.books DROP CONSTRAINT books_pkey;
DROP TABLE public.users;
DROP TABLE public.tomebooks;
DROP TABLE public.sessions;
DROP TABLE public.semesters;
DROP TABLE public.patrons;
DROP TABLE public.library_access;
DROP TABLE public.libraries;
DROP TABLE public.classes;
DROP TABLE public.classbooks;
DROP SEQUENCE public.checkouts_id_seq;
DROP TABLE public.checkouts;
DROP TABLE public.books;
DROP FUNCTION public.isbn_force_upper();
DROP PROCEDURAL LANGUAGE plpgsql;
DROP SCHEMA public;
--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'Standard public namespace';


--
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: 
--

CREATE PROCEDURAL LANGUAGE plpgsql;


--
-- Name: isbn_force_upper(); Type: FUNCTION; Schema: public; Owner: tome
--

CREATE FUNCTION isbn_force_upper() RETURNS "trigger"
    AS $$
begin
NEW.isbn := upper(NEW.isbn);
return NEW;
end;
$$
    LANGUAGE plpgsql;


SET default_tablespace = '';

SET default_with_oids = true;

--
-- Name: books; Type: TABLE; Schema: public; Owner: tome; Tablespace: 
--

CREATE TABLE books (
    isbn character varying(20) NOT NULL,
    title text NOT NULL,
    author text NOT NULL,
    edition text
);


--
-- Name: checkouts; Type: TABLE; Schema: public; Owner: tome; Tablespace: 
--

CREATE TABLE checkouts (
    tomebook bigint NOT NULL,
    semester smallint NOT NULL,
    checkout timestamp with time zone DEFAULT now() NOT NULL,
    checkin timestamp with time zone,
    comments text,
    reservation boolean DEFAULT false NOT NULL,
    library integer NOT NULL,
    uid integer NOT NULL,
    id integer DEFAULT nextval(('public.checkouts_id_seq'::text)::regclass) NOT NULL,
    borrower integer NOT NULL,
    CONSTRAINT checkout_or_reservation CHECK ((NOT ((reservation = true) AND (checkin IS NOT NULL)))),
    CONSTRAINT timeline CHECK (((checkin IS NULL) OR (checkin > checkout)))
);


--
-- Name: checkouts_id_seq; Type: SEQUENCE; Schema: public; Owner: tome
--

CREATE SEQUENCE checkouts_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: classbooks; Type: TABLE; Schema: public; Owner: tome; Tablespace: 
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
-- Name: classes; Type: TABLE; Schema: public; Owner: tome; Tablespace: 
--

CREATE TABLE classes (
    id character varying(10) NOT NULL,
    name text NOT NULL,
    comments text
);


--
-- Name: libraries; Type: TABLE; Schema: public; Owner: tome; Tablespace: 
--

CREATE TABLE libraries (
    id serial NOT NULL,
    name text NOT NULL
);


--
-- Name: library_access; Type: TABLE; Schema: public; Owner: tome; Tablespace: 
--

CREATE TABLE library_access (
    uid integer NOT NULL,
    library integer NOT NULL
);


--
-- Name: patrons; Type: TABLE; Schema: public; Owner: tome; Tablespace: 
--

CREATE TABLE patrons (
    id serial NOT NULL,
    email text NOT NULL,
    name text NOT NULL
);


--
-- Name: semesters; Type: TABLE; Schema: public; Owner: tome; Tablespace: 
--

CREATE TABLE semesters (
    id serial NOT NULL,
    name text NOT NULL,
    current boolean DEFAULT false NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: tome; Tablespace: 
--

CREATE TABLE sessions (
    id character(32) NOT NULL,
    a_session text NOT NULL
);


--
-- Name: tomebooks; Type: TABLE; Schema: public; Owner: tome; Tablespace: 
--

CREATE TABLE tomebooks (
    id serial NOT NULL,
    isbn character varying(20) NOT NULL,
    expire smallint,
    comments text,
    timedonated timestamp with time zone DEFAULT now() NOT NULL,
    library integer NOT NULL,
    timeremoved timestamp with time zone,
    originator integer NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: tome; Tablespace: 
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
-- Name: books_pkey; Type: CONSTRAINT; Schema: public; Owner: tome; Tablespace: 
--

ALTER TABLE ONLY books
    ADD CONSTRAINT books_pkey PRIMARY KEY (isbn);


--
-- Name: checkouts_pkey; Type: CONSTRAINT; Schema: public; Owner: tome; Tablespace: 
--

ALTER TABLE ONLY checkouts
    ADD CONSTRAINT checkouts_pkey PRIMARY KEY (id);


--
-- Name: classbooks_pkey; Type: CONSTRAINT; Schema: public; Owner: tome; Tablespace: 
--

ALTER TABLE ONLY classbooks
    ADD CONSTRAINT classbooks_pkey PRIMARY KEY ("class", isbn);


--
-- Name: classes_pkey; Type: CONSTRAINT; Schema: public; Owner: tome; Tablespace: 
--

ALTER TABLE ONLY classes
    ADD CONSTRAINT classes_pkey PRIMARY KEY (id);


--
-- Name: libraries_pkey; Type: CONSTRAINT; Schema: public; Owner: tome; Tablespace: 
--

ALTER TABLE ONLY libraries
    ADD CONSTRAINT libraries_pkey PRIMARY KEY (id);


--
-- Name: patrons_pkey; Type: CONSTRAINT; Schema: public; Owner: tome; Tablespace: 
--

ALTER TABLE ONLY patrons
    ADD CONSTRAINT patrons_pkey PRIMARY KEY (id);


--
-- Name: semesters_pkey; Type: CONSTRAINT; Schema: public; Owner: tome; Tablespace: 
--

ALTER TABLE ONLY semesters
    ADD CONSTRAINT semesters_pkey PRIMARY KEY (id);


--
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: tome; Tablespace: 
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: tomebooks_pkey; Type: CONSTRAINT; Schema: public; Owner: tome; Tablespace: 
--

ALTER TABLE ONLY tomebooks
    ADD CONSTRAINT tomebooks_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: tome; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: one_borrower; Type: INDEX; Schema: public; Owner: tome; Tablespace: 
--

CREATE UNIQUE INDEX one_borrower ON checkouts USING btree (tomebook) WHERE ((checkin IS NULL) AND (reservation = false));


--
-- Name: one_current; Type: INDEX; Schema: public; Owner: tome; Tablespace: 
--

CREATE UNIQUE INDEX one_current ON semesters USING btree (current) WHERE (current = true);


--
-- Name: one_reservation; Type: INDEX; Schema: public; Owner: tome; Tablespace: 
--

CREATE UNIQUE INDEX one_reservation ON checkouts USING btree (tomebook, semester) WHERE (reservation = true);


--
-- Name: upper_email_unique; Type: INDEX; Schema: public; Owner: tome; Tablespace: 
--

CREATE UNIQUE INDEX upper_email_unique ON patrons USING btree (upper(email));


--
-- Name: upper_isbn; Type: INDEX; Schema: public; Owner: tome; Tablespace: 
--

CREATE UNIQUE INDEX upper_isbn ON books USING btree (upper((isbn)::text));


--
-- Name: upper_username; Type: INDEX; Schema: public; Owner: tome; Tablespace: 
--

CREATE UNIQUE INDEX upper_username ON users USING btree (upper(username));


--
-- Name: isbn_force_upper; Type: TRIGGER; Schema: public; Owner: tome
--

CREATE TRIGGER isbn_force_upper
    BEFORE INSERT OR UPDATE ON books
    FOR EACH ROW
    EXECUTE PROCEDURE isbn_force_upper();


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY tomebooks
    ADD CONSTRAINT "$1" FOREIGN KEY (isbn) REFERENCES books(isbn);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY checkouts
    ADD CONSTRAINT "$1" FOREIGN KEY (tomebook) REFERENCES tomebooks(id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY classbooks
    ADD CONSTRAINT "$1" FOREIGN KEY ("class") REFERENCES classes(id);


--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY library_access
    ADD CONSTRAINT "$1" FOREIGN KEY (uid) REFERENCES users(id);


--
-- Name: $2; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY classbooks
    ADD CONSTRAINT "$2" FOREIGN KEY (isbn) REFERENCES books(isbn);


--
-- Name: $2; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY library_access
    ADD CONSTRAINT "$2" FOREIGN KEY (library) REFERENCES libraries(id);


--
-- Name: borrower_fk; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY checkouts
    ADD CONSTRAINT borrower_fk FOREIGN KEY (borrower) REFERENCES patrons(id);


--
-- Name: expirefk; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY tomebooks
    ADD CONSTRAINT expirefk FOREIGN KEY (expire) REFERENCES semesters(id) MATCH FULL;


--
-- Name: libraryfk; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY tomebooks
    ADD CONSTRAINT libraryfk FOREIGN KEY (library) REFERENCES libraries(id) MATCH FULL;


--
-- Name: libraryfk; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY checkouts
    ADD CONSTRAINT libraryfk FOREIGN KEY (library) REFERENCES libraries(id) MATCH FULL;


--
-- Name: originator_fk; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY tomebooks
    ADD CONSTRAINT originator_fk FOREIGN KEY (originator) REFERENCES patrons(id);


--
-- Name: semesterfk; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY checkouts
    ADD CONSTRAINT semesterfk FOREIGN KEY (semester) REFERENCES semesters(id) MATCH FULL;


--
-- Name: userfk; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY classbooks
    ADD CONSTRAINT userfk FOREIGN KEY (uid) REFERENCES users(id) MATCH FULL;


--
-- Name: userfk; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY checkouts
    ADD CONSTRAINT userfk FOREIGN KEY (uid) REFERENCES users(id) MATCH FULL;


--
-- Name: verifiedfk; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY classbooks
    ADD CONSTRAINT verifiedfk FOREIGN KEY (verified) REFERENCES semesters(id) MATCH FULL;


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--
