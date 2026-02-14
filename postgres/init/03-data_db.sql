\connect data_db

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
-- Name: data_set; Type: TABLE
--
CREATE TABLE public.data_set (
    set_id integer NOT NULL,
    set_name character varying(50),
    table_num integer,
    set_desc character varying(50),
    create_time timestamp without time zone,
    is_delete integer,
    delete_time timestamp without time zone,
    user_id integer,
    is_public integer
);
ALTER TABLE public.data_set OWNER TO postgres;

CREATE SEQUENCE public.data_set_set_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.data_set_set_id_seq OWNER TO postgres;
ALTER SEQUENCE public.data_set_set_id_seq OWNED BY public.data_set.set_id;
ALTER TABLE ONLY public.data_set ALTER COLUMN set_id SET DEFAULT nextval('public.data_set_set_id_seq'::regclass);
ALTER TABLE ONLY public.data_set ADD CONSTRAINT data_set_pkey PRIMARY KEY (set_id);


--
-- Name: data_table; Type: TABLE
--
CREATE TABLE public.data_table (
    table_id integer NOT NULL,
    table_name character varying(50),
    set_id integer,
    table_desc character varying(255),
    data_table_name character varying(50),
    col_num integer,
    row_num integer,
    create_time timestamp without time zone,
    is_delete integer,
    delete_time timestamp without time zone,
    table_type character varying(50),
    user_id integer
);
ALTER TABLE public.data_table OWNER TO postgres;

CREATE SEQUENCE public.data_table_table_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.data_table_table_id_seq OWNER TO postgres;
ALTER SEQUENCE public.data_table_table_id_seq OWNED BY public.data_table.table_id;
ALTER TABLE ONLY public.data_table ALTER COLUMN table_id SET DEFAULT nextval('public.data_table_table_id_seq'::regclass);
ALTER TABLE ONLY public.data_table ADD CONSTRAINT data_table_pkey PRIMARY KEY (table_id);


--
-- Name: data_columns; Type: TABLE
--
CREATE TABLE public.data_columns (
    col_id integer NOT NULL,
    col_name character varying(50),
    table_id integer,
    col_type character varying(50),
    var_type character varying(50),
    create_time timestamp without time zone,
    is_delete integer,
    delete_time timestamp without time zone
);
ALTER TABLE public.data_columns OWNER TO postgres;

CREATE SEQUENCE public.data_columns_col_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.data_columns_col_id_seq OWNER TO postgres;
ALTER SEQUENCE public.data_columns_col_id_seq OWNED BY public.data_columns.col_id;
ALTER TABLE ONLY public.data_columns ALTER COLUMN col_id SET DEFAULT nextval('public.data_columns_col_id_seq'::regclass);
ALTER TABLE ONLY public.data_columns ADD CONSTRAINT data_columns_pkey PRIMARY KEY (col_id);


--
-- Name: tag_data_statistics; Type: TABLE
--
CREATE TABLE public.tag_data_statistics (
    __id integer NOT NULL,
    set_id integer,
    table_id integer,
    tag character varying(255),
    tag_statistic text,
    is_delete integer,
    sql_table_name character varying(255),
    delete_time timestamp without time zone
);
ALTER TABLE public.tag_data_statistics OWNER TO postgres;

COMMENT ON COLUMN public.tag_data_statistics.__id IS '内置id';
COMMENT ON COLUMN public.tag_data_statistics.set_id IS '数据集id';
COMMENT ON COLUMN public.tag_data_statistics.table_id IS '表id';
COMMENT ON COLUMN public.tag_data_statistics.tag IS '标签名';
COMMENT ON COLUMN public.tag_data_statistics.tag_statistic IS '标签对应的实体统计信息';
COMMENT ON COLUMN public.tag_data_statistics.is_delete IS '对应表是否删除';
COMMENT ON COLUMN public.tag_data_statistics.sql_table_name IS '在用户数据表中存的数据表名';
COMMENT ON COLUMN public.tag_data_statistics.delete_time IS '删除时间';

CREATE SEQUENCE public.tag_data_statistics_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;
ALTER SEQUENCE public.tag_data_statistics_id OWNER TO postgres;
ALTER SEQUENCE public.tag_data_statistics_id OWNED BY public.tag_data_statistics.__id;
ALTER TABLE ONLY public.tag_data_statistics ALTER COLUMN __id SET DEFAULT nextval('public.tag_data_statistics_id'::regclass);
ALTER TABLE ONLY public.tag_data_statistics ADD CONSTRAINT tag_data_statistics_pkey PRIMARY KEY (__id);


--
-- Name: named_entity_statistics; Type: TABLE
--
CREATE TABLE public.named_entity_statistics (
    id integer NOT NULL,
    statistical_information text,
    table_id character varying(255),
    label_details text
);
ALTER TABLE public.named_entity_statistics OWNER TO postgres;
COMMENT ON COLUMN public.named_entity_statistics.statistical_information IS '标注统计信息';
COMMENT ON COLUMN public.named_entity_statistics.table_id IS '命名实体数据表id';
COMMENT ON COLUMN public.named_entity_statistics.label_details IS '标签的内容';
ALTER TABLE ONLY public.named_entity_statistics ADD CONSTRAINT named_entity_statistics_pkey PRIMARY KEY (id);
