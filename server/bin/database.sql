--
-- PostgreSQL database dump
--

-- Dumped from database version 16.6 (Ubuntu 16.6-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 17.1

-- Started on 2025-01-26 10:01:36

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 216 (class 1259 OID 16391)
-- Name: accounts; Type: TABLE; Schema: public; Owner: server
--

CREATE TABLE public.accounts (
    id integer NOT NULL,
    email text NOT NULL,
    password text NOT NULL,
    characters integer DEFAULT 3,
    banned boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.accounts OWNER TO server;

--
-- TOC entry 215 (class 1259 OID 16390)
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: server
--

CREATE SEQUENCE public.accounts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.accounts_id_seq OWNER TO server;

--
-- TOC entry 3425 (class 0 OID 0)
-- Dependencies: 215
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: server
--

ALTER SEQUENCE public.accounts_id_seq OWNED BY public.accounts.id;


--
-- TOC entry 219 (class 1259 OID 16419)
-- Name: character_accounts; Type: TABLE; Schema: public; Owner: server
--

CREATE TABLE public.character_accounts (
    account_id integer NOT NULL,
    character_id integer NOT NULL
);


ALTER TABLE public.character_accounts OWNER TO server;

--
-- TOC entry 218 (class 1259 OID 16406)
-- Name: characters; Type: TABLE; Schema: public; Owner: server
--

CREATE TABLE public.characters (
    id integer NOT NULL,
    name text NOT NULL,
    color text NOT NULL,
    is_male boolean DEFAULT false NOT NULL,
    hair text NOT NULL,
    hair_color text NOT NULL,
    eye text NOT NULL,
    eye_color text NOT NULL,
    shirt text NOT NULL,
    pants text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.characters OWNER TO server;

--
-- TOC entry 217 (class 1259 OID 16405)
-- Name: characters_id_seq; Type: SEQUENCE; Schema: public; Owner: server
--

CREATE SEQUENCE public.characters_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.characters_id_seq OWNER TO server;

--
-- TOC entry 3426 (class 0 OID 0)
-- Dependencies: 217
-- Name: characters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: server
--

ALTER SEQUENCE public.characters_id_seq OWNED BY public.characters.id;


--
-- TOC entry 3256 (class 2604 OID 16394)
-- Name: accounts id; Type: DEFAULT; Schema: public; Owner: server
--

ALTER TABLE ONLY public.accounts ALTER COLUMN id SET DEFAULT nextval('public.accounts_id_seq'::regclass);


--
-- TOC entry 3261 (class 2604 OID 16409)
-- Name: characters id; Type: DEFAULT; Schema: public; Owner: server
--

ALTER TABLE ONLY public.characters ALTER COLUMN id SET DEFAULT nextval('public.characters_id_seq'::regclass);


--
-- TOC entry 3266 (class 2606 OID 16404)
-- Name: accounts accounts_email_key; Type: CONSTRAINT; Schema: public; Owner: server
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_email_key UNIQUE (email);


--
-- TOC entry 3268 (class 2606 OID 16402)
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: server
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- TOC entry 3274 (class 2606 OID 16423)
-- Name: character_accounts character_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: server
--

ALTER TABLE ONLY public.character_accounts
    ADD CONSTRAINT character_accounts_pkey PRIMARY KEY (account_id, character_id);


--
-- TOC entry 3270 (class 2606 OID 16418)
-- Name: characters characters_name_key; Type: CONSTRAINT; Schema: public; Owner: server
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_name_key UNIQUE (name);


--
-- TOC entry 3272 (class 2606 OID 16416)
-- Name: characters characters_pkey; Type: CONSTRAINT; Schema: public; Owner: server
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_pkey PRIMARY KEY (id);


--
-- TOC entry 3275 (class 2606 OID 16424)
-- Name: character_accounts character_accounts_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: server
--

ALTER TABLE ONLY public.character_accounts
    ADD CONSTRAINT character_accounts_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3276 (class 2606 OID 16429)
-- Name: character_accounts character_accounts_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: server
--

ALTER TABLE ONLY public.character_accounts
    ADD CONSTRAINT character_accounts_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON UPDATE CASCADE ON DELETE CASCADE;


-- Completed on 2025-01-26 10:01:38

--
-- PostgreSQL database dump complete
--

