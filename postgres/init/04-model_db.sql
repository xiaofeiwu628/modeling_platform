\connect model_db

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

CREATE SCHEMA IF NOT EXISTS public;
ALTER SCHEMA public OWNER TO postgres;
SET default_tablespace = '';
SET default_table_access_method = heap;

--
-- Name: model_repository; Type: TABLE
--
CREATE TABLE public.model_repository (
    model_id bigint NOT NULL,
    task_id character varying(50),
    task_history_id character varying(50),
    model_name character varying(50),
    model_desc character varying(255),
    model_state character varying(50),
    is_public integer DEFAULT 0,
    user_id integer,
    create_time timestamp without time zone,
    is_delete integer DEFAULT 0,
    delete_time timestamp without time zone
);
ALTER TABLE public.model_repository OWNER TO postgres;
ALTER TABLE ONLY public.model_repository ADD CONSTRAINT model_repository_pkey PRIMARY KEY (model_id);


--
-- Name: image_repository; Type: TABLE
--
CREATE TABLE public.image_repository (
    image_id bigint NOT NULL,
    image_name character varying(50),
    image_desc character varying(255),
    image_state character varying(50),
    is_public integer DEFAULT 0,
    user_id integer,
    create_time timestamp without time zone,
    is_delete integer DEFAULT 0,
    delete_time timestamp without time zone
);
ALTER TABLE public.image_repository OWNER TO postgres;
ALTER TABLE ONLY public.image_repository ADD CONSTRAINT image_repository_pkey PRIMARY KEY (image_id);


--
-- Name: image_version_repository; Type: TABLE
--
CREATE TABLE public.image_version_repository (
    image_version_id bigint NOT NULL,
    create_time timestamp without time zone,
    is_delete integer DEFAULT 0,
    delete_time timestamp without time zone,
    tag character varying(50),
    image_id bigint,
    version_desc character varying(255),
    is_used integer DEFAULT 0
);
ALTER TABLE public.image_version_repository OWNER TO postgres;
ALTER TABLE ONLY public.image_version_repository ADD CONSTRAINT image_version_repository_pkey PRIMARY KEY (image_version_id);
