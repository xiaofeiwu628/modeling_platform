\connect task_db

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
-- Name: calculate_time_consuming(); Type: FUNCTION
--
CREATE FUNCTION public.calculate_time_consuming() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  
BEGIN  
    new.time_consuming = date_part('sec', new.end_time::timestamp - old.start_time::timestamp);
	RETURN NEW;  
END;  
$$;
ALTER FUNCTION public.calculate_time_consuming() OWNER TO postgres;


--
-- Name: task; Type: TABLE
--
CREATE TABLE public.task (
    task_id character varying(50) NOT NULL,
    task_desc character varying(255),
    name character varying(50),
    state character varying(20),
    type character varying(50),
    configuration json,
    create_time timestamp without time zone,
    is_delete integer DEFAULT 0,
    delete_time timestamp without time zone,
    user_id integer
);
ALTER TABLE public.task OWNER TO postgres;
ALTER TABLE ONLY public.task ADD CONSTRAINT task_pkey PRIMARY KEY (task_id);


--
-- Name: task_state; Type: TABLE
--
CREATE TABLE public.task_state (
    task_id character varying(50) NOT NULL,
    train_id character varying(50) NOT NULL,
    history_id character varying(50),
    step character varying(50),
    time_consuming double precision,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    state character varying(50),
    is_delete integer DEFAULT 0,
    delete_time timestamp without time zone,
    user_id integer
);
ALTER TABLE public.task_state OWNER TO postgres;
ALTER TABLE ONLY public.task_state ADD CONSTRAINT task_state_pkey PRIMARY KEY (task_id, train_id);
-- Trigger
CREATE TRIGGER ctc BEFORE UPDATE OF end_time ON public.task_state FOR EACH ROW EXECUTE FUNCTION public.calculate_time_consuming();


--
-- Name: train_result; Type: TABLE
--
CREATE TABLE public.train_result (
    task_id character varying(50) NOT NULL,
    history_id character varying(50) NOT NULL,
    step character varying(50),
    model_conf jsonb,
    path character varying(255),
    evaluation jsonb,
    create_time timestamp without time zone,
    is_delete integer DEFAULT 0,
    delete_time timestamp without time zone,
    request_data jsonb
);
ALTER TABLE public.train_result OWNER TO postgres;
ALTER TABLE ONLY public.train_result ADD CONSTRAINT train_result_pkey PRIMARY KEY (task_id, history_id);


--
-- Name: online_service; Type: TABLE
--
CREATE TABLE public.online_service (
    service_id bigint NOT NULL,
    model_id bigint,
    task_id character varying(50),
    task_history_id character varying(50),
    service_name character varying(50),
    service_desc character varying(255),
    service_state character varying(50),
    memory double precision,
    cpu_cores_num integer,
    url character varying(255),
    kong_url character varying(255),
    extra_conf jsonb,
    is_public integer DEFAULT 0,
    user_id integer,
    create_time timestamp without time zone,
    is_delete integer DEFAULT 0,
    delete_time timestamp without time zone,
    service_type character varying(50),
    image_version_id bigint,
    image_port character varying(50),
    image_name character varying(255),
    env jsonb
);
ALTER TABLE public.online_service OWNER TO postgres;
ALTER TABLE ONLY public.online_service ADD CONSTRAINT online_service_pkey PRIMARY KEY (service_id);


--
-- Name: online_service_log; Type: TABLE
--
CREATE TABLE public.online_service_log (
    online_service_log_id bigint NOT NULL,
    service_id bigint,
    status_code integer,
    response_status character varying(255),
    request_start_time timestamp without time zone,
    request_end_time timestamp without time zone,
    response_duration integer
);
ALTER TABLE public.online_service_log OWNER TO postgres;
ALTER TABLE ONLY public.online_service_log ADD CONSTRAINT online_service_log_pkey PRIMARY KEY (online_service_log_id);
