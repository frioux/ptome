--
-- PostgreSQL database dump
--

SET client_encoding = 'SQL_ASCII';
SET check_function_bodies = false;

SET SESSION AUTHORIZATION 'postgres';

--
-- TOC entry 4 (OID 2200)
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


SET SESSION AUTHORIZATION 'tome';

SET search_path = public, pg_catalog;

--
-- TOC entry 6 (OID 42307)
-- Name: books; Type: TABLE; Schema: public; Owner: tome
--

CREATE TABLE books (
    isbn character varying(20) NOT NULL,
    title text NOT NULL,
    author text NOT NULL,
    edition text
);


--
-- TOC entry 7 (OID 42312)
-- Name: classes; Type: TABLE; Schema: public; Owner: tome
--

CREATE TABLE classes (
    id character varying(10) NOT NULL,
    name text NOT NULL,
    comments text
);


--
-- TOC entry 8 (OID 42319)
-- Name: tomebooks; Type: TABLE; Schema: public; Owner: tome
--

CREATE TABLE tomebooks (
    id serial NOT NULL,
    isbn character varying(20) NOT NULL,
    originator text NOT NULL,
    expire smallint,
    comments text,
    timedonated timestamp with time zone DEFAULT now() NOT NULL,
    library integer NOT NULL,
    timeremoved timestamp with time zone
);


--
-- TOC entry 9 (OID 42326)
-- Name: checkouts; Type: TABLE; Schema: public; Owner: tome
--

CREATE TABLE checkouts (
    tomebook bigint NOT NULL,
    semester smallint NOT NULL,
    borrower text NOT NULL,
    checkout timestamp with time zone DEFAULT now() NOT NULL,
    checkin timestamp with time zone,
    comments text,
    reservation boolean DEFAULT false NOT NULL,
    library integer NOT NULL,
    uid integer NOT NULL,
    id integer DEFAULT nextval('public.checkouts_id_seq'::text) NOT NULL,
    CONSTRAINT checkout_or_reservation CHECK ((NOT ((reservation = true) AND (checkin IS NOT NULL)))),
    CONSTRAINT timeline CHECK (((checkin IS NULL) OR (checkin > checkout)))
);


--
-- TOC entry 10 (OID 42333)
-- Name: classbooks; Type: TABLE; Schema: public; Owner: tome
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
-- TOC entry 11 (OID 76080)
-- Name: users; Type: TABLE; Schema: public; Owner: tome
--

CREATE TABLE users (
    id serial NOT NULL,
    username text NOT NULL,
    email text NOT NULL,
    notifications boolean DEFAULT true NOT NULL,
    admin boolean DEFAULT false NOT NULL,
    "password" text NOT NULL,
    disabled boolean DEFAULT false NOT NULL
);


--
-- TOC entry 12 (OID 76090)
-- Name: libraries; Type: TABLE; Schema: public; Owner: tome
--

CREATE TABLE libraries (
    id serial NOT NULL,
    name text NOT NULL
);


--
-- TOC entry 13 (OID 76098)
-- Name: library_access; Type: TABLE; Schema: public; Owner: tome
--

CREATE TABLE library_access (
    uid integer NOT NULL,
    library integer NOT NULL
);


--
-- TOC entry 14 (OID 76129)
-- Name: sessions; Type: TABLE; Schema: public; Owner: tome
--

CREATE TABLE sessions (
    id character(32) NOT NULL,
    a_session text NOT NULL
);


--
-- TOC entry 15 (OID 76186)
-- Name: semesters; Type: TABLE; Schema: public; Owner: tome
--

CREATE TABLE semesters (
    id serial NOT NULL,
    name text NOT NULL,
    current boolean DEFAULT false NOT NULL
);


--
-- TOC entry 5 (OID 76259)
-- Name: checkouts_id_seq; Type: SEQUENCE; Schema: public; Owner: tome
--

CREATE SEQUENCE checkouts_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- TOC entry 20 (OID 76179)
-- Name: one_borrower; Type: INDEX; Schema: public; Owner: tome
--

CREATE UNIQUE INDEX one_borrower ON checkouts USING btree (tomebook) WHERE ((checkin IS NULL) AND (reservation = false));


--
-- TOC entry 21 (OID 76180)
-- Name: one_reservation; Type: INDEX; Schema: public; Owner: tome
--

CREATE UNIQUE INDEX one_reservation ON checkouts USING btree (tomebook, semester) WHERE (reservation = true);


--
-- TOC entry 27 (OID 76195)
-- Name: one_current; Type: INDEX; Schema: public; Owner: tome
--

CREATE UNIQUE INDEX one_current ON semesters USING btree (current) WHERE (current = true);


--
-- TOC entry 16 (OID 43025)
-- Name: books_pkey; Type: CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY books
    ADD CONSTRAINT books_pkey PRIMARY KEY (isbn);


--
-- TOC entry 17 (OID 43027)
-- Name: classes_pkey; Type: CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY classes
    ADD CONSTRAINT classes_pkey PRIMARY KEY (id);


--
-- TOC entry 18 (OID 43029)
-- Name: tomebooks_pkey; Type: CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY tomebooks
    ADD CONSTRAINT tomebooks_pkey PRIMARY KEY (id);


--
-- TOC entry 22 (OID 43033)
-- Name: classbooks_pkey; Type: CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY classbooks
    ADD CONSTRAINT classbooks_pkey PRIMARY KEY ("class", isbn);


--
-- TOC entry 24 (OID 76086)
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 25 (OID 76096)
-- Name: libraries_pkey; Type: CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY libraries
    ADD CONSTRAINT libraries_pkey PRIMARY KEY (id);


--
-- TOC entry 26 (OID 76134)
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 23 (OID 76140)
-- Name: usernameu; Type: CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY users
    ADD CONSTRAINT usernameu UNIQUE (username);


--
-- TOC entry 28 (OID 76193)
-- Name: semesters_pkey; Type: CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY semesters
    ADD CONSTRAINT semesters_pkey PRIMARY KEY (id);


--
-- TOC entry 19 (OID 76262)
-- Name: checkouts_pkey; Type: CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY checkouts
    ADD CONSTRAINT checkouts_pkey PRIMARY KEY (id);


--
-- TOC entry 30 (OID 43035)
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY tomebooks
    ADD CONSTRAINT "$1" FOREIGN KEY (isbn) REFERENCES books(isbn);


--
-- TOC entry 34 (OID 43039)
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY checkouts
    ADD CONSTRAINT "$1" FOREIGN KEY (tomebook) REFERENCES tomebooks(id);


--
-- TOC entry 37 (OID 43043)
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY classbooks
    ADD CONSTRAINT "$1" FOREIGN KEY ("class") REFERENCES classes(id);


--
-- TOC entry 38 (OID 43047)
-- Name: $2; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY classbooks
    ADD CONSTRAINT "$2" FOREIGN KEY (isbn) REFERENCES books(isbn);


--
-- TOC entry 40 (OID 76100)
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY library_access
    ADD CONSTRAINT "$1" FOREIGN KEY (uid) REFERENCES users(id);


--
-- TOC entry 41 (OID 76104)
-- Name: $2; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY library_access
    ADD CONSTRAINT "$2" FOREIGN KEY (library) REFERENCES libraries(id);


--
-- TOC entry 29 (OID 76110)
-- Name: libraryfk; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY tomebooks
    ADD CONSTRAINT libraryfk FOREIGN KEY (library) REFERENCES libraries(id) MATCH FULL;


--
-- TOC entry 36 (OID 76117)
-- Name: userfk; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY classbooks
    ADD CONSTRAINT userfk FOREIGN KEY (uid) REFERENCES users(id) MATCH FULL;


--
-- TOC entry 32 (OID 76121)
-- Name: libraryfk; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY checkouts
    ADD CONSTRAINT libraryfk FOREIGN KEY (library) REFERENCES libraries(id) MATCH FULL;


--
-- TOC entry 33 (OID 76125)
-- Name: userfk; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY checkouts
    ADD CONSTRAINT userfk FOREIGN KEY (uid) REFERENCES users(id) MATCH FULL;


--
-- TOC entry 35 (OID 76205)
-- Name: semesterfk; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY checkouts
    ADD CONSTRAINT semesterfk FOREIGN KEY (semester) REFERENCES semesters(id) MATCH FULL;


--
-- TOC entry 31 (OID 76221)
-- Name: expirefk; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY tomebooks
    ADD CONSTRAINT expirefk FOREIGN KEY (expire) REFERENCES semesters(id) MATCH FULL;


--
-- TOC entry 39 (OID 76225)
-- Name: verifiedfk; Type: FK CONSTRAINT; Schema: public; Owner: tome
--

ALTER TABLE ONLY classbooks
    ADD CONSTRAINT verifiedfk FOREIGN KEY (verified) REFERENCES semesters(id) MATCH FULL;

---  Make usernames case insensitive
create unique index upper_username on users (upper(username));

--- Prevent duplicate ISBNs by case
create UNIQUE INDEX upper_isbn on books upper(isbn);

SET SESSION AUTHORIZATION 'postgres';

--
-- TOC entry 3 (OID 2200)
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'Standard public namespace';


