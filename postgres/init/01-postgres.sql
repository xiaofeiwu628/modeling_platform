--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2 (Debian 17.2-1.pgdg120+1)
-- Dumped by pg_dump version 17.2 (Debian 17.2-1.pgdg120+1)

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

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA IF NOT EXISTS public;


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: select_container_resource_by_id(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.select_container_resource_by_id(node_id text, container_id text) RETURNS TABLE(cur_time text, cpu double precision, cpu_total numeric, memory double precision, memory_total numeric, gpu double precision, gpu_total numeric, gpu_memory double precision, gpu_memory_total numeric)
    LANGUAGE plpgsql
    AS $$
declare 
    a bool := false;
    b bool := false;
	t_name1 text;
	t_name2 text;
begin
	-- 查询格林尼治的时间，查看是否存在当前时间的分区表
	t_name1 := to_char(now() - interval '8 hours', 'yyyy_mm_dd_hh24');
    if EXISTS (select 1 from public.partition_table where table_name = t_name1) then
        a := true;
    end if;
	-- 查询上一个小时的分区表是否存在
	t_name2 := to_char(now() - interval '9 hours', 'yyyy_mm_dd_hh24');
	if EXISTS (select 1 from public.partition_table where table_name = t_name2) then
        b := true;
    end if;
	
	-- 如果当前小时和上个小时的分区表都存在，则返回这两个小时的信息
	if a and b then
		return query execute
		'select to_char("time",''yyyy-MM-dd hh24:MI'') as tt, avg(cpu_percent), avg(cpu_total),
			avg(memory_percent), avg(memory_total), avg(gpu_percent), avg(gpu_total), avg(gpu_memory_percent), avg(gpu_memory_total) 
		from public.ctable_'|| t_name2 ||'
		where node_id='''||node_id||''' and container_id='''|| container_id || '''
		group by tt
		union all
		select to_char("time",''yyyy-MM-dd hh24:MI'') as tt, avg(cpu_percent), avg(cpu_total),
			avg(memory_percent), avg(memory_total), avg(gpu_percent), avg(gpu_total), avg(gpu_memory_percent), avg(gpu_memory_total) 
		from public.ctable_'|| t_name1 ||'
		where node_id='''||node_id||''' and container_id='''|| container_id || '''
		group by tt
		order by tt;';
			
    end if;
    -- 如果当前时间的分区表存在，返回当前分区
    if a then 
        raise notice 'a';
    end if;
    -- 如果上一小时的分区表存在，返回
    if b then
        raise notice 'b ';
    end if;
end
$$;


ALTER FUNCTION public.select_container_resource_by_id(node_id text, container_id text) OWNER TO postgres;

--
-- Name: select_container_resource_by_id2(text, text, interval); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.select_container_resource_by_id2(node_id text, container_id text, duration interval) RETURNS TABLE(cur_time text, cpu double precision, cpu_total numeric, memory double precision, memory_total numeric, gpu double precision, gpu_total numeric, gpu_memory double precision, gpu_memory_total numeric, networkrx numeric, networktx numeric, block_read numeric, block_write numeric)
    LANGUAGE plpgsql
    AS $$
declare 
	t_name timestamp;
begin
	-- 查询格林尼治的时间，查看是否存在当前时间的分区表
	t_name := (now() - duration);
    
	return query execute
	'select to_char("time",''yyyy-MM-dd hh24:MI'') as tt, avg(cpu_percent), avg(cpu_total),
			avg(memory_percent), avg(memory_total), avg(gpu_percent), avg(gpu_total), avg(gpu_memory_percent), avg(gpu_memory_total),
			avg(networkrx), avg(networktx), avg(block_read), avg(block_write)
		from public.container_resource2
		where "time" > ''' || t_name || ''' and node_id='''||node_id||''' and container_id='''|| container_id || '''
		group by tt
		order by tt;';
	
end
$$;


ALTER FUNCTION public.select_container_resource_by_id2(node_id text, container_id text, duration interval) OWNER TO postgres;

--
-- Name: select_node_resource(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.select_node_resource() RETURNS TABLE(cur_time text, cpu double precision, cpu_total numeric, memory double precision, memory_total numeric, gpu double precision, gpu_total numeric, gpu_memory double precision, gpu_memory_total numeric)
    LANGUAGE plpgsql
    AS $$
declare 
    a bool := false;
    b bool := false;
	t_name1 text;
	t_name2 text;
begin
	-- 查询格林尼治的时间，查看是否存在当前时间的分区表
	t_name1 := to_char(now() - interval '8 hours', 'yyyy_mm_dd_hh24');
    if EXISTS (select 1 from public.partition_table where table_name = t_name1) then
        a := true;
    end if;
	-- 查询上一个小时的分区表是否存在
	t_name2 := to_char(now() - interval '9 hours', 'yyyy_mm_dd_hh24');
	if EXISTS (select 1 from public.partition_table where table_name = t_name2) then
        b := true;
    end if;
	
	-- 如果当前小时和上个小时的分区表都存在，则返回这两个小时的信息
	if a and b then
		return query execute
		'with sss as (
					select avg(cpu_total) as cpu_total, avg(memory_total) as memory_total, avg(gpu_total) as gpu_total, avg(gpu_memory_total) as gpu_memory_total
					from public.ctable_'||t_name1||'
					group by node_id
			)
			select to_char("time",''yyyy-MM-dd hh24:MI'') as tt,
			case when (select avg(cpu_total) from sss)=0 then 0 else avg(cpu_total * cpu_percent) / (select sum(cpu_total) from sss) end as avg_cpu_percent,
			(select sum(cpu_total) from sss) as cpu_total,
			case when (select avg(memory_total) from sss)=0 then 0 else avg(memory_total * memory_percent) / (select avg(memory_total) from sss) end as avg_memory_percent,
			(select sum(memory_total) from sss) as memory_total,
			case when (select avg(gpu_total) from sss)=0 then 0 else avg(gpu_total * gpu_percent) / (select avg(gpu_total) from sss) end as avg_gpu_total,
			(select sum(gpu_total) from sss) as gpu_total,
			case when (select avg(gpu_memory_total) from sss)=0 then 0 else avg(gpu_memory_total * gpu_memory_percent) / (select avg(gpu_memory_total) from sss) end as avg_gpu_memory_percent,
			(select sum(gpu_memory_total) from sss) as gpu_memory_total
			from public.ntable_'||t_name2||'
			group by tt
			union all
			select to_char("time",''yyyy-MM-dd hh24:MI'') as tt,
			case when (select avg(cpu_total) from sss)=0 then 0 else avg(cpu_total * cpu_percent) / (select sum(cpu_total) from sss) end as avg_cpu_percent,
			(select sum(cpu_total) from sss) as cpu_total,
			case when (select avg(memory_total) from sss)=0 then 0 else avg(memory_total * memory_percent) / (select avg(memory_total) from sss) end as avg_memory_percent,
			(select sum(memory_total) from sss) as memory_total,
			case when (select avg(gpu_total) from sss)=0 then 0 else avg(gpu_total * gpu_percent) / (select avg(gpu_total) from sss) end as avg_gpu_total,
			(select sum(gpu_total) from sss) as gpu_total,
			case when (select avg(gpu_memory_total) from sss)=0 then 0 else avg(gpu_memory_total * gpu_memory_percent) / (select avg(gpu_memory_total) from sss) end as avg_gpu_memory_percent,
			(select sum(gpu_memory_total) from sss) as gpu_memory_total
			from public.ntable_'||t_name1||'
			group by tt
			order by tt;';
			
    end if;
    -- 如果当前时间的分区表存在，返回当前分区
    if a then 
        raise notice 'a';
    end if;
    -- 如果上一小时的分区表存在，返回
    if b then
        raise notice 'b ';
    end if;
end
$$;


ALTER FUNCTION public.select_node_resource() OWNER TO postgres;

--
-- Name: select_node_resource2(interval); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.select_node_resource2(duration interval) RETURNS TABLE(cur_time text, cpu double precision, cpu_total numeric, memory double precision, memory_total numeric, gpu double precision, gpu_total numeric, gpu_memory double precision, gpu_memory_total numeric)
    LANGUAGE plpgsql
    AS $$
declare 
	t_name timestamp;
begin
	-- 查询格林尼治的时间，查看是否存在当前时间的分区表
	t_name := (now() - duration);
    
	return query execute
	'with sss as (
		select avg(cpu_total) as cpu_total, avg(memory_total) as memory_total, avg(gpu_total) as gpu_total, avg(gpu_memory_total) as gpu_memory_total
		from public.node_resource2
		where "time" > ''' || t_name || '''
		group by node_id
	)
	select to_char("time",''yyyy-MM-dd hh24:MI'') as tt,
	case when (select avg(cpu_total) from sss)=0 then 0 else avg(cpu_total * cpu_percent) / (select sum(cpu_total) from sss) end as avg_cpu_percent,
	(select sum(cpu_total) from sss) as cpu_total,
	case when (select avg(memory_total) from sss)=0 then 0 else avg(memory_total * memory_percent) / (select avg(memory_total) from sss) end as avg_memory_percent,
	(select sum(memory_total) from sss) as memory_total,
	case when (select avg(gpu_total) from sss)=0 then 0 else avg(gpu_total * gpu_percent) / (select avg(gpu_total) from sss) end as avg_gpu_total,
	(select sum(gpu_total) from sss) as gpu_total,
	case when (select avg(gpu_memory_total) from sss)=0 then 0 else avg(gpu_memory_total * gpu_memory_percent) / (select avg(gpu_memory_total) from sss) end as avg_gpu_memory_percent,
	(select sum(gpu_memory_total) from sss) as gpu_memory_total
	from public.node_resource2
	where "time" > ''' || t_name || '''
	group by tt
	order by tt;';
	
end
$$;


ALTER FUNCTION public.select_node_resource2(duration interval) OWNER TO postgres;

--
-- Name: select_node_resource_by_id(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.select_node_resource_by_id(node_id text) RETURNS TABLE(cur_time text, cpu double precision, cpu_total numeric, memory double precision, memory_total numeric, gpu double precision, gpu_total numeric, gpu_memory double precision, gpu_memory_total numeric)
    LANGUAGE plpgsql
    AS $$
declare 
    a bool := false;
    b bool := false;
	t_name1 text;
	t_name2 text;
begin
	-- 查询格林尼治的时间，查看是否存在当前时间的分区表
	t_name1 := to_char(now() - interval '8 hours', 'yyyy_mm_dd_hh24');
    if EXISTS (select 1 from public.partition_table where table_name = t_name1) then
        a := true;
    end if;
	-- 查询上一个小时的分区表是否存在
	t_name2 := to_char(now() - interval '9 hours', 'yyyy_mm_dd_hh24');
	if EXISTS (select 1 from public.partition_table where table_name = t_name2) then
        b := true;
    end if;
	
	-- 如果当前小时和上个小时的分区表都存在，则返回这两个小时的信息
	if a and b then
		return query execute
		'select to_char("time",''yyyy-MM-dd hh24:MI'') as tt, avg(cpu_percent), avg(cpu_total),
			avg(memory_percent), avg(memory_total), avg(gpu_percent), avg(gpu_total), avg(gpu_memory_percent), avg(gpu_memory_total) 
		from public.ntable_'|| t_name2 ||'
		where node_id='''||node_id||'''
		group by tt
		union all
		select to_char("time",''yyyy-MM-dd hh24:MI'') as tt, avg(cpu_percent), avg(cpu_total),
			avg(memory_percent), avg(memory_total), avg(gpu_percent), avg(gpu_total), avg(gpu_memory_percent), avg(gpu_memory_total) 
		from public.ntable_'|| t_name1 ||'
		where node_id='''||node_id||'''
		group by tt
		order by tt;';
			
    end if;
    -- 如果当前时间的分区表存在，返回当前分区
    if a then 
        raise notice 'a';
    end if;
    -- 如果上一小时的分区表存在，返回
    if b then
        raise notice 'b ';
    end if;
end
$$;


ALTER FUNCTION public.select_node_resource_by_id(node_id text) OWNER TO postgres;

--
-- Name: select_node_resource_by_id2(text, interval); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.select_node_resource_by_id2(node_id text, duration interval) RETURNS TABLE(cur_time text, cpu double precision, cpu_total numeric, memory double precision, memory_total numeric, gpu double precision, gpu_total numeric, gpu_memory double precision, gpu_memory_total numeric)
    LANGUAGE plpgsql
    AS $$
declare 
	t_name timestamp;
begin
	-- 查询格林尼治的时间，查看是否存在当前时间的分区表
	t_name := (now() - duration);
    
	return query execute
	'select to_char("time",''yyyy-MM-dd hh24:MI'') as tt, avg(cpu_percent), avg(cpu_total),
			avg(memory_percent), avg(memory_total), avg(gpu_percent), avg(gpu_total), avg(gpu_memory_percent), avg(gpu_memory_total) 
		from public.node_resource2
		where "time" > ''' || t_name || ''' and node_id='''||node_id||'''
		group by tt
		order by tt;';
	
end
$$;


ALTER FUNCTION public.select_node_resource_by_id2(node_id text, duration interval) OWNER TO postgres;

--
-- Name: update_timestamp(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
   t_name text;
   d text;
   create_table text;
   create_index text;
BEGIN
	-- 将分区表的名称命名为 2022_09_06_21
	t_name := to_char(new.time,'yyyy_mm_dd_hh24');
	-- 如果分区表存在则不执行
	if EXISTS (select 1 from public.partition_table where table_name = t_name) then
		return null;
	end if;
	-- 创建分区表并建立索引
	d := to_char(new.time,'yyyy-mm-dd hh24');
	EXECUTE 'CREATE TABLE ntable_' || t_name || ' PARTITION of public.node_resource for VALUES from (''' || d || ':00:00'') to (''' || d || ':59:59.99'')';
	EXECUTE 'create INDEX nindex_' || t_name ||' on ntable_' || t_name || '(time)';
	EXECUTE 'CREATE TABLE ctable_' || t_name || ' PARTITION of public.container_resource for VALUES from (''' || d || ':00:00'') to (''' || d || ':59:59.99'')';
	EXECUTE 'create INDEX cindex_' || t_name ||' on ctable_' || t_name || '(time)';
  	new.table_name = t_name;
 	return new;
end
$$;


ALTER FUNCTION public.update_timestamp() OWNER TO postgres;

--
-- Name: update_timestamp1(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_timestamp1() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
   t_name text;
   tt text;
   f bool :=true;
BEGIN
	t_name := to_char(now(),'yyyymmdd');
	if EXISTS (select 1 from public.partition_table1 where table_name = t_name) then
		f := false;
		return null;
	end if;
-- 	new.age= to_char(tt,'yyyy_mm_dd_hh24');
	if f then
		EXECUTE 'CREATE TABLE ntable1_' || t_name || ' PARTITION of public.node_resource1 for VALUES in ('''|| t_name ||''')';
		EXECUTE 'create INDEX nindex1_' || t_name ||' on ntable1_' || t_name || '(time_date)';
		EXECUTE 'CREATE TABLE ctable1_' || t_name || ' PARTITION of public.container_resource1 for VALUES in ('''|| t_name ||''')';
		EXECUTE 'create INDEX cindex1_' || t_name ||' on ctable1_' || t_name || '(time_date)';
		-- 删除七天前的数据
		tt := to_char(now() - interval '7 days', 'yyyymmdd');
		-- 如果七天前的数据存在则删除
		if EXISTS (select 1 from public.partition_table1 where table_name = tt) then
			EXECUTE 'DROP TABLE if exists ntable1_' || tt || ';';
			EXECUTE 'DROP TABLE if exists ctable1_' || tt || ';';
			EXECUTE 'DELETE FROM public.partition_table1 WHERE table_name = '|| tt;
		end if;
		
		new.table_name = t_name;
		return new;
	end if;
end
$$;


ALTER FUNCTION public.update_timestamp1() OWNER TO postgres;

--
-- Name: update_timestamp2(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_timestamp2() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	ts timestamp;
   	t_name text;
	t_name2 text;
   	tt text;
   	f bool :=true;
BEGIN
	ts := now();
	t_name := to_char(ts,'yyyymmdd');
	if EXISTS (select 1 from public.partition_table2 where table_name = t_name) then
		f := false;
		return null;
	end if;
-- 	new.age= to_char(tt,'yyyy_mm_dd_hh24');
	if f then
		t_name2 := to_char(ts + interval '1 days','yyyymmdd');
		EXECUTE 'CREATE TABLE ntable2_' || t_name || ' PARTITION of public.node_resource2 for VALUES from (''' || t_name || ''') to (''' || t_name2 || ''')';

		EXECUTE 'create INDEX nindex2_' || t_name ||' on ntable2_' || t_name || ' ("time")';
		EXECUTE 'CREATE TABLE ctable2_' || t_name || ' PARTITION of public.container_resource2 for VALUES from (''' || t_name || ''') to (''' || t_name2 || ''')';
		EXECUTE 'create INDEX cindex2_' || t_name ||' on ctable2_' || t_name || ' ("time")';
		-- 删除七天前的数据
		tt := to_char(ts - interval '7 days', 'yyyymmdd');
		-- 如果七天前的数据存在则删除
		if EXISTS (select 1 from public.partition_table2 where table_name = tt) then
			EXECUTE 'DROP TABLE if exists ntable2_' || tt || ';';
			EXECUTE 'DROP TABLE if exists ctable2_' || tt || ';';
			EXECUTE 'DELETE FROM public.partition_table2 WHERE table_name = '''|| tt || ''';';
		end if;
		
		new.table_name = t_name;
		return new;
	end if;
end
$$;


ALTER FUNCTION public.update_timestamp2() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: aaa; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.aaa (
    s integer NOT NULL,
    f integer NOT NULL
);


ALTER TABLE public.aaa OWNER TO postgres;

--
-- Name: container_resource; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.container_resource (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
)
PARTITION BY RANGE ("time");


ALTER TABLE public.container_resource OWNER TO postgres;

--
-- Name: container_resource1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.container_resource1 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    time_date character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
)
PARTITION BY LIST (time_date);


ALTER TABLE public.container_resource1 OWNER TO postgres;

--
-- Name: container_resource2; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.container_resource2 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
)
PARTITION BY RANGE ("time");


ALTER TABLE public.container_resource2 OWNER TO postgres;

--
-- Name: ctable1_20220910; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable1_20220910 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    time_date character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable1_20220910 OWNER TO postgres;

--
-- Name: ctable1_20220912; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable1_20220912 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    time_date character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable1_20220912 OWNER TO postgres;

--
-- Name: ctable1_20220913; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable1_20220913 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    time_date character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable1_20220913 OWNER TO postgres;

--
-- Name: ctable2_20221108; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20221108 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20221108 OWNER TO postgres;

--
-- Name: ctable2_20221109; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20221109 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20221109 OWNER TO postgres;

--
-- Name: ctable2_20221110; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20221110 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20221110 OWNER TO postgres;

--
-- Name: ctable2_20221114; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20221114 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20221114 OWNER TO postgres;

--
-- Name: ctable2_20221118; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20221118 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20221118 OWNER TO postgres;

--
-- Name: ctable2_20221211; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20221211 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20221211 OWNER TO postgres;

--
-- Name: ctable2_20230119; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230119 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230119 OWNER TO postgres;

--
-- Name: ctable2_20230120; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230120 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230120 OWNER TO postgres;

--
-- Name: ctable2_20230121; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230121 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230121 OWNER TO postgres;

--
-- Name: ctable2_20230122; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230122 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230122 OWNER TO postgres;

--
-- Name: ctable2_20230210; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230210 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230210 OWNER TO postgres;

--
-- Name: ctable2_20230211; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230211 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230211 OWNER TO postgres;

--
-- Name: ctable2_20230212; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230212 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230212 OWNER TO postgres;

--
-- Name: ctable2_20230213; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230213 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230213 OWNER TO postgres;

--
-- Name: ctable2_20230214; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230214 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230214 OWNER TO postgres;

--
-- Name: ctable2_20230215; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230215 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230215 OWNER TO postgres;

--
-- Name: ctable2_20230423; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230423 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230423 OWNER TO postgres;

--
-- Name: ctable2_20230424; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230424 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230424 OWNER TO postgres;

--
-- Name: ctable2_20230425; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230425 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230425 OWNER TO postgres;

--
-- Name: ctable2_20230426; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230426 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230426 OWNER TO postgres;

--
-- Name: ctable2_20230427; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230427 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230427 OWNER TO postgres;

--
-- Name: ctable2_20230428; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230428 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230428 OWNER TO postgres;

--
-- Name: ctable2_20230609; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230609 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230609 OWNER TO postgres;

--
-- Name: ctable2_20230610; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230610 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230610 OWNER TO postgres;

--
-- Name: ctable2_20230912; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230912 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230912 OWNER TO postgres;

--
-- Name: ctable2_20230913; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230913 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230913 OWNER TO postgres;

--
-- Name: ctable2_20230914; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230914 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230914 OWNER TO postgres;

--
-- Name: ctable2_20230915; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230915 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230915 OWNER TO postgres;

--
-- Name: ctable2_20230916; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230916 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230916 OWNER TO postgres;

--
-- Name: ctable2_20230917; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230917 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230917 OWNER TO postgres;

--
-- Name: ctable2_20230918; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20230918 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20230918 OWNER TO postgres;

--
-- Name: ctable2_20231118; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20231118 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20231118 OWNER TO postgres;

--
-- Name: ctable2_20231119; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20231119 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20231119 OWNER TO postgres;

--
-- Name: ctable2_20231120; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20231120 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20231120 OWNER TO postgres;

--
-- Name: ctable2_20231121; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20231121 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20231121 OWNER TO postgres;

--
-- Name: ctable2_20231122; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20231122 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20231122 OWNER TO postgres;

--
-- Name: ctable2_20231123; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20231123 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20231123 OWNER TO postgres;

--
-- Name: ctable2_20231124; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20231124 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20231124 OWNER TO postgres;

--
-- Name: ctable2_20240213; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20240213 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20240213 OWNER TO postgres;

--
-- Name: ctable2_20240214; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20240214 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20240214 OWNER TO postgres;

--
-- Name: ctable2_20240215; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20240215 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20240215 OWNER TO postgres;

--
-- Name: ctable2_20240216; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20240216 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20240216 OWNER TO postgres;

--
-- Name: ctable2_20240217; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20240217 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20240217 OWNER TO postgres;

--
-- Name: ctable2_20240218; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20240218 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20240218 OWNER TO postgres;

--
-- Name: ctable2_20240219; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20240219 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20240219 OWNER TO postgres;

--
-- Name: ctable2_20250225; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250225 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250225 OWNER TO postgres;

--
-- Name: ctable2_20250226; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250226 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250226 OWNER TO postgres;

--
-- Name: ctable2_20250227; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250227 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250227 OWNER TO postgres;

--
-- Name: ctable2_20250228; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250228 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250228 OWNER TO postgres;

--
-- Name: ctable2_20250314; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250314 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250314 OWNER TO postgres;

--
-- Name: ctable2_20250315; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250315 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250315 OWNER TO postgres;

--
-- Name: ctable2_20250316; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250316 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250316 OWNER TO postgres;

--
-- Name: ctable2_20250317; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250317 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250317 OWNER TO postgres;

--
-- Name: ctable2_20250318; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250318 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250318 OWNER TO postgres;

--
-- Name: ctable2_20250319; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250319 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250319 OWNER TO postgres;

--
-- Name: ctable2_20250320; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250320 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250320 OWNER TO postgres;

--
-- Name: ctable2_20250506; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250506 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250506 OWNER TO postgres;

--
-- Name: ctable2_20250507; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250507 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250507 OWNER TO postgres;

--
-- Name: ctable2_20250710; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250710 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250710 OWNER TO postgres;

--
-- Name: ctable2_20250711; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250711 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250711 OWNER TO postgres;

--
-- Name: ctable2_20250712; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250712 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250712 OWNER TO postgres;

--
-- Name: ctable2_20250713; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250713 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250713 OWNER TO postgres;

--
-- Name: ctable2_20250828; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250828 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250828 OWNER TO postgres;

--
-- Name: ctable2_20250829; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250829 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250829 OWNER TO postgres;

--
-- Name: ctable2_20250830; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250830 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250830 OWNER TO postgres;

--
-- Name: ctable2_20250831; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250831 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250831 OWNER TO postgres;

--
-- Name: ctable2_20250901; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250901 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250901 OWNER TO postgres;

--
-- Name: ctable2_20250902; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250902 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250902 OWNER TO postgres;

--
-- Name: ctable2_20250903; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20250903 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20250903 OWNER TO postgres;

--
-- Name: ctable2_20260102; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20260102 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20260102 OWNER TO postgres;

--
-- Name: ctable2_20260103; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20260103 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20260103 OWNER TO postgres;

--
-- Name: ctable2_20260104; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20260104 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20260104 OWNER TO postgres;

--
-- Name: ctable2_20260105; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20260105 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20260105 OWNER TO postgres;

--
-- Name: ctable2_20260106; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20260106 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20260106 OWNER TO postgres;

--
-- Name: ctable2_20260107; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20260107 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20260107 OWNER TO postgres;

--
-- Name: ctable2_20260108; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable2_20260108 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real,
    networkrx bigint,
    networktx bigint,
    block_read bigint,
    block_write bigint
);


ALTER TABLE public.ctable2_20260108 OWNER TO postgres;

--
-- Name: ctable_2022_09_06_17; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_06_17 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_06_17 OWNER TO postgres;

--
-- Name: ctable_2022_09_06_18; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_06_18 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_06_18 OWNER TO postgres;

--
-- Name: ctable_2022_09_06_19; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_06_19 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_06_19 OWNER TO postgres;

--
-- Name: ctable_2022_09_06_20; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_06_20 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_06_20 OWNER TO postgres;

--
-- Name: ctable_2022_09_06_21; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_06_21 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_06_21 OWNER TO postgres;

--
-- Name: ctable_2022_09_06_22; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_06_22 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_06_22 OWNER TO postgres;

--
-- Name: ctable_2022_09_06_23; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_06_23 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_06_23 OWNER TO postgres;

--
-- Name: ctable_2022_09_07_00; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_07_00 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_07_00 OWNER TO postgres;

--
-- Name: ctable_2022_09_07_01; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_07_01 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_07_01 OWNER TO postgres;

--
-- Name: ctable_2022_09_07_02; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_07_02 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_07_02 OWNER TO postgres;

--
-- Name: ctable_2022_09_07_12; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_07_12 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_07_12 OWNER TO postgres;

--
-- Name: ctable_2022_09_07_14; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_07_14 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_07_14 OWNER TO postgres;

--
-- Name: ctable_2022_09_07_15; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_07_15 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_07_15 OWNER TO postgres;

--
-- Name: ctable_2022_09_07_16; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_07_16 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_07_16 OWNER TO postgres;

--
-- Name: ctable_2022_09_07_17; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_07_17 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_07_17 OWNER TO postgres;

--
-- Name: ctable_2022_09_07_18; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_07_18 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_07_18 OWNER TO postgres;

--
-- Name: ctable_2022_09_07_19; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_07_19 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_07_19 OWNER TO postgres;

--
-- Name: ctable_2022_09_07_20; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_07_20 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_07_20 OWNER TO postgres;

--
-- Name: ctable_2022_09_07_21; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_07_21 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_07_21 OWNER TO postgres;

--
-- Name: ctable_2022_09_07_22; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_07_22 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_07_22 OWNER TO postgres;

--
-- Name: ctable_2022_09_07_23; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_07_23 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_07_23 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_00; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_00 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_00 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_01; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_01 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_01 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_02; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_02 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_02 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_03; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_03 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_03 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_04; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_04 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_04 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_05; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_05 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_05 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_06; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_06 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_06 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_07; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_07 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_07 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_08; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_08 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_08 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_09; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_09 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_09 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_10; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_10 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_10 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_11; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_11 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_11 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_12; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_12 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_12 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_13; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_13 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_13 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_14; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_14 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_14 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_15; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_15 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_15 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_16; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_16 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_16 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_17; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_17 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_17 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_18; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_18 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_18 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_19; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_19 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_19 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_20; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_20 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_20 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_21; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_21 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_21 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_22; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_22 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_22 OWNER TO postgres;

--
-- Name: ctable_2022_09_08_23; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_08_23 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_08_23 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_00; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_00 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_00 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_01; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_01 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_01 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_02; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_02 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_02 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_03; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_03 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_03 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_04; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_04 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_04 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_05; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_05 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_05 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_06; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_06 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_06 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_07; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_07 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_07 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_08; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_08 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_08 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_09; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_09 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_09 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_10; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_10 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_10 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_11; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_11 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_11 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_12; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_12 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_12 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_13; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_13 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_13 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_14; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_14 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_14 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_15; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_15 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_15 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_16; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_16 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_16 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_17; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_17 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_17 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_18; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_18 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_18 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_19; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_19 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_19 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_20; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_20 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_20 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_21; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_21 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_21 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_22; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_22 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_22 OWNER TO postgres;

--
-- Name: ctable_2022_09_09_23; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_09_23 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_09_23 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_00; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_00 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_00 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_01; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_01 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_01 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_02; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_02 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_02 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_03; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_03 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_03 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_04; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_04 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_04 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_05; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_05 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_05 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_06; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_06 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_06 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_07; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_07 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_07 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_08; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_08 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_08 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_09; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_09 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_09 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_10; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_10 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_10 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_11; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_11 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_11 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_12; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_12 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_12 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_13; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_13 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_13 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_14; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_14 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_14 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_15; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_15 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_15 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_16; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_16 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_16 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_17; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_17 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_17 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_18; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_18 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_18 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_19; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_19 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_19 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_20; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_20 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_20 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_21; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_21 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_21 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_22; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_22 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_22 OWNER TO postgres;

--
-- Name: ctable_2022_09_10_23; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_10_23 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_10_23 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_00; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_00 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_00 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_01; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_01 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_01 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_02; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_02 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_02 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_03; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_03 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_03 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_04; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_04 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_04 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_05; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_05 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_05 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_06; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_06 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_06 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_07; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_07 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_07 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_08; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_08 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_08 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_09; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_09 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_09 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_10; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_10 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_10 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_11; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_11 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_11 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_12; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_12 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_12 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_13; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_13 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_13 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_14; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_14 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_14 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_15; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_15 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_15 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_16; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_16 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_16 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_17; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_17 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_17 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_18; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_18 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_18 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_19; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_19 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_19 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_20; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_20 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_20 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_21; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_21 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_21 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_22; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_22 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_22 OWNER TO postgres;

--
-- Name: ctable_2022_09_11_23; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_11_23 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_11_23 OWNER TO postgres;

--
-- Name: ctable_2022_09_12_00; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_12_00 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_12_00 OWNER TO postgres;

--
-- Name: ctable_2022_09_12_01; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_12_01 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_12_01 OWNER TO postgres;

--
-- Name: ctable_2022_09_12_02; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_12_02 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_12_02 OWNER TO postgres;

--
-- Name: ctable_2022_09_12_03; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_12_03 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_12_03 OWNER TO postgres;

--
-- Name: ctable_2022_09_12_11; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ctable_2022_09_12_11 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    container_id character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    status character varying(10) NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ctable_2022_09_12_11 OWNER TO postgres;

--
-- Name: node_list; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.node_list (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    create_time timestamp with time zone NOT NULL,
    alias character varying(30),
    is_delete boolean NOT NULL,
    delete_time timestamp with time zone
);


ALTER TABLE public.node_list OWNER TO postgres;

--
-- Name: COLUMN node_list.node_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.node_list.node_id IS '节点id';


--
-- Name: COLUMN node_list.ip_addr; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.node_list.ip_addr IS 'ip地址';


--
-- Name: COLUMN node_list.create_time; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.node_list.create_time IS '加入时间';


--
-- Name: COLUMN node_list.alias; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.node_list.alias IS '节点别名';


--
-- Name: COLUMN node_list.is_delete; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.node_list.is_delete IS '是否删除';


--
-- Name: COLUMN node_list.delete_time; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.node_list.delete_time IS '删除时间';


--
-- Name: node_resource; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.node_resource (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
)
PARTITION BY RANGE ("time");


ALTER TABLE public.node_resource OWNER TO postgres;

--
-- Name: node_resource1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.node_resource1 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    time_date character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
)
PARTITION BY LIST (time_date);


ALTER TABLE public.node_resource1 OWNER TO postgres;

--
-- Name: node_resource2; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.node_resource2 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
)
PARTITION BY RANGE ("time");


ALTER TABLE public.node_resource2 OWNER TO postgres;

--
-- Name: ntable1_20220910; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable1_20220910 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    time_date character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable1_20220910 OWNER TO postgres;

--
-- Name: ntable1_20220912; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable1_20220912 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    time_date character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable1_20220912 OWNER TO postgres;

--
-- Name: ntable1_20220913; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable1_20220913 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    time_date character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable1_20220913 OWNER TO postgres;

--
-- Name: ntable2_20221108; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20221108 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20221108 OWNER TO postgres;

--
-- Name: ntable2_20221109; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20221109 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20221109 OWNER TO postgres;

--
-- Name: ntable2_20221110; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20221110 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20221110 OWNER TO postgres;

--
-- Name: ntable2_20221114; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20221114 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20221114 OWNER TO postgres;

--
-- Name: ntable2_20221118; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20221118 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20221118 OWNER TO postgres;

--
-- Name: ntable2_20221211; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20221211 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20221211 OWNER TO postgres;

--
-- Name: ntable2_20230119; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230119 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230119 OWNER TO postgres;

--
-- Name: ntable2_20230120; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230120 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230120 OWNER TO postgres;

--
-- Name: ntable2_20230121; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230121 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230121 OWNER TO postgres;

--
-- Name: ntable2_20230122; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230122 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230122 OWNER TO postgres;

--
-- Name: ntable2_20230210; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230210 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230210 OWNER TO postgres;

--
-- Name: ntable2_20230211; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230211 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230211 OWNER TO postgres;

--
-- Name: ntable2_20230212; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230212 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230212 OWNER TO postgres;

--
-- Name: ntable2_20230213; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230213 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230213 OWNER TO postgres;

--
-- Name: ntable2_20230214; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230214 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230214 OWNER TO postgres;

--
-- Name: ntable2_20230215; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230215 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230215 OWNER TO postgres;

--
-- Name: ntable2_20230423; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230423 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230423 OWNER TO postgres;

--
-- Name: ntable2_20230424; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230424 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230424 OWNER TO postgres;

--
-- Name: ntable2_20230425; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230425 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230425 OWNER TO postgres;

--
-- Name: ntable2_20230426; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230426 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230426 OWNER TO postgres;

--
-- Name: ntable2_20230427; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230427 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230427 OWNER TO postgres;

--
-- Name: ntable2_20230428; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230428 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230428 OWNER TO postgres;

--
-- Name: ntable2_20230609; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230609 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230609 OWNER TO postgres;

--
-- Name: ntable2_20230610; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230610 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230610 OWNER TO postgres;

--
-- Name: ntable2_20230912; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230912 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230912 OWNER TO postgres;

--
-- Name: ntable2_20230913; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230913 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230913 OWNER TO postgres;

--
-- Name: ntable2_20230914; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230914 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230914 OWNER TO postgres;

--
-- Name: ntable2_20230915; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230915 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230915 OWNER TO postgres;

--
-- Name: ntable2_20230916; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230916 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230916 OWNER TO postgres;

--
-- Name: ntable2_20230917; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230917 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230917 OWNER TO postgres;

--
-- Name: ntable2_20230918; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20230918 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20230918 OWNER TO postgres;

--
-- Name: ntable2_20231118; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20231118 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20231118 OWNER TO postgres;

--
-- Name: ntable2_20231119; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20231119 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20231119 OWNER TO postgres;

--
-- Name: ntable2_20231120; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20231120 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20231120 OWNER TO postgres;

--
-- Name: ntable2_20231121; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20231121 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20231121 OWNER TO postgres;

--
-- Name: ntable2_20231122; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20231122 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20231122 OWNER TO postgres;

--
-- Name: ntable2_20231123; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20231123 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20231123 OWNER TO postgres;

--
-- Name: ntable2_20231124; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20231124 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20231124 OWNER TO postgres;

--
-- Name: ntable2_20240213; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20240213 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20240213 OWNER TO postgres;

--
-- Name: ntable2_20240214; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20240214 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20240214 OWNER TO postgres;

--
-- Name: ntable2_20240215; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20240215 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20240215 OWNER TO postgres;

--
-- Name: ntable2_20240216; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20240216 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20240216 OWNER TO postgres;

--
-- Name: ntable2_20240217; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20240217 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20240217 OWNER TO postgres;

--
-- Name: ntable2_20240218; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20240218 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20240218 OWNER TO postgres;

--
-- Name: ntable2_20240219; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20240219 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20240219 OWNER TO postgres;

--
-- Name: ntable2_20250225; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250225 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250225 OWNER TO postgres;

--
-- Name: ntable2_20250226; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250226 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250226 OWNER TO postgres;

--
-- Name: ntable2_20250227; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250227 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250227 OWNER TO postgres;

--
-- Name: ntable2_20250228; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250228 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250228 OWNER TO postgres;

--
-- Name: ntable2_20250314; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250314 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250314 OWNER TO postgres;

--
-- Name: ntable2_20250315; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250315 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250315 OWNER TO postgres;

--
-- Name: ntable2_20250316; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250316 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250316 OWNER TO postgres;

--
-- Name: ntable2_20250317; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250317 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250317 OWNER TO postgres;

--
-- Name: ntable2_20250318; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250318 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250318 OWNER TO postgres;

--
-- Name: ntable2_20250319; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250319 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250319 OWNER TO postgres;

--
-- Name: ntable2_20250320; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250320 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250320 OWNER TO postgres;

--
-- Name: ntable2_20250506; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250506 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250506 OWNER TO postgres;

--
-- Name: ntable2_20250507; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250507 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250507 OWNER TO postgres;

--
-- Name: ntable2_20250710; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250710 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250710 OWNER TO postgres;

--
-- Name: ntable2_20250711; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250711 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250711 OWNER TO postgres;

--
-- Name: ntable2_20250712; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250712 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250712 OWNER TO postgres;

--
-- Name: ntable2_20250713; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250713 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250713 OWNER TO postgres;

--
-- Name: ntable2_20250828; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250828 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250828 OWNER TO postgres;

--
-- Name: ntable2_20250829; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250829 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250829 OWNER TO postgres;

--
-- Name: ntable2_20250830; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250830 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250830 OWNER TO postgres;

--
-- Name: ntable2_20250831; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250831 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250831 OWNER TO postgres;

--
-- Name: ntable2_20250901; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250901 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250901 OWNER TO postgres;

--
-- Name: ntable2_20250902; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250902 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250902 OWNER TO postgres;

--
-- Name: ntable2_20250903; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20250903 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20250903 OWNER TO postgres;

--
-- Name: ntable2_20260102; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20260102 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20260102 OWNER TO postgres;

--
-- Name: ntable2_20260103; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20260103 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20260103 OWNER TO postgres;

--
-- Name: ntable2_20260104; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20260104 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20260104 OWNER TO postgres;

--
-- Name: ntable2_20260105; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20260105 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20260105 OWNER TO postgres;

--
-- Name: ntable2_20260106; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20260106 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20260106 OWNER TO postgres;

--
-- Name: ntable2_20260107; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20260107 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20260107 OWNER TO postgres;

--
-- Name: ntable2_20260108; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable2_20260108 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable2_20260108 OWNER TO postgres;

--
-- Name: ntable_2022_09_06_23; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_06_23 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_06_23 OWNER TO postgres;

--
-- Name: ntable_2022_09_07_00; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_07_00 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_07_00 OWNER TO postgres;

--
-- Name: ntable_2022_09_07_01; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_07_01 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_07_01 OWNER TO postgres;

--
-- Name: ntable_2022_09_07_02; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_07_02 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_07_02 OWNER TO postgres;

--
-- Name: ntable_2022_09_07_12; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_07_12 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_07_12 OWNER TO postgres;

--
-- Name: ntable_2022_09_07_14; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_07_14 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_07_14 OWNER TO postgres;

--
-- Name: ntable_2022_09_07_15; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_07_15 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_07_15 OWNER TO postgres;

--
-- Name: ntable_2022_09_07_16; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_07_16 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_07_16 OWNER TO postgres;

--
-- Name: ntable_2022_09_07_17; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_07_17 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_07_17 OWNER TO postgres;

--
-- Name: ntable_2022_09_07_18; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_07_18 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_07_18 OWNER TO postgres;

--
-- Name: ntable_2022_09_07_19; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_07_19 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_07_19 OWNER TO postgres;

--
-- Name: ntable_2022_09_07_20; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_07_20 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_07_20 OWNER TO postgres;

--
-- Name: ntable_2022_09_07_21; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_07_21 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_07_21 OWNER TO postgres;

--
-- Name: ntable_2022_09_07_22; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_07_22 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_07_22 OWNER TO postgres;

--
-- Name: ntable_2022_09_07_23; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_07_23 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_07_23 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_00; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_00 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_00 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_01; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_01 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_01 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_02; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_02 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_02 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_03; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_03 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_03 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_04; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_04 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_04 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_05; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_05 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_05 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_06; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_06 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_06 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_07; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_07 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_07 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_08; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_08 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_08 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_09; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_09 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_09 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_10; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_10 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_10 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_11; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_11 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_11 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_12; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_12 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_12 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_13; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_13 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_13 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_14; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_14 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_14 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_15; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_15 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_15 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_16; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_16 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_16 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_17; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_17 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_17 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_18; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_18 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_18 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_19; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_19 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_19 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_20; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_20 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_20 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_21; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_21 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_21 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_22; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_22 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_22 OWNER TO postgres;

--
-- Name: ntable_2022_09_08_23; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_08_23 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_08_23 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_00; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_00 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_00 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_01; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_01 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_01 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_02; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_02 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_02 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_03; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_03 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_03 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_04; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_04 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_04 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_05; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_05 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_05 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_06; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_06 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_06 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_07; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_07 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_07 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_08; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_08 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_08 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_09; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_09 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_09 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_10; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_10 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_10 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_11; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_11 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_11 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_12; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_12 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_12 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_13; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_13 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_13 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_14; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_14 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_14 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_15; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_15 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_15 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_16; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_16 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_16 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_17; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_17 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_17 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_18; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_18 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_18 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_19; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_19 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_19 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_20; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_20 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_20 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_21; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_21 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_21 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_22; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_22 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_22 OWNER TO postgres;

--
-- Name: ntable_2022_09_09_23; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_09_23 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_09_23 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_00; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_00 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_00 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_01; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_01 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_01 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_02; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_02 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_02 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_03; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_03 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_03 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_04; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_04 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_04 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_05; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_05 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_05 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_06; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_06 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_06 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_07; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_07 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_07 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_08; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_08 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_08 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_09; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_09 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_09 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_10; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_10 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_10 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_11; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_11 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_11 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_12; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_12 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_12 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_13; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_13 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_13 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_14; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_14 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_14 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_15; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_15 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_15 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_16; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_16 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_16 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_17; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_17 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_17 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_18; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_18 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_18 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_19; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_19 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_19 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_20; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_20 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_20 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_21; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_21 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_21 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_22; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_22 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_22 OWNER TO postgres;

--
-- Name: ntable_2022_09_10_23; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_10_23 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_10_23 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_00; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_00 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_00 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_01; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_01 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_01 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_02; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_02 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_02 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_03; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_03 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_03 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_04; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_04 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_04 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_05; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_05 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_05 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_06; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_06 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_06 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_07; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_07 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_07 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_08; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_08 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_08 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_09; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_09 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_09 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_10; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_10 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_10 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_11; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_11 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_11 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_12; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_12 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_12 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_13; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_13 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_13 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_14; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_14 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_14 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_15; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_15 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_15 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_16; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_16 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_16 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_17; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_17 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_17 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_18; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_18 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_18 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_19; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_19 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_19 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_20; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_20 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_20 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_21; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_21 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_21 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_22; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_22 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_22 OWNER TO postgres;

--
-- Name: ntable_2022_09_11_23; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_11_23 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_11_23 OWNER TO postgres;

--
-- Name: ntable_2022_09_12_00; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_12_00 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_12_00 OWNER TO postgres;

--
-- Name: ntable_2022_09_12_01; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_12_01 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_12_01 OWNER TO postgres;

--
-- Name: ntable_2022_09_12_02; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_12_02 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_12_02 OWNER TO postgres;

--
-- Name: ntable_2022_09_12_03; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_12_03 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_12_03 OWNER TO postgres;

--
-- Name: ntable_2022_09_12_11; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ntable_2022_09_12_11 (
    node_id character varying(20) NOT NULL,
    ip_addr character varying(20) NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cpu_total integer,
    cpu_percent real,
    memory_total bigint,
    memory_percent real,
    gpu_total integer,
    gpu_percent real,
    gpu_memory_total bigint,
    gpu_memory_percent real
);


ALTER TABLE public.ntable_2022_09_12_11 OWNER TO postgres;

--
-- Name: partition_table; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.partition_table (
    table_name character varying(20) NOT NULL,
    "time" timestamp with time zone,
    age character varying(60)
);


ALTER TABLE public.partition_table OWNER TO postgres;

--
-- Name: partition_table1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.partition_table1 (
    table_name character varying(20) NOT NULL
);


ALTER TABLE public.partition_table1 OWNER TO postgres;

--
-- Name: partition_table2; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.partition_table2 (
    table_name character varying(20) NOT NULL
);


ALTER TABLE public.partition_table2 OWNER TO postgres;

--
-- Name: test; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.test (
    aid integer NOT NULL,
    model character varying(100)
);


ALTER TABLE public.test OWNER TO postgres;

--
-- Name: ctable1_20220910; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource1 ATTACH PARTITION public.ctable1_20220910 FOR VALUES IN ('20220910');


--
-- Name: ctable1_20220912; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource1 ATTACH PARTITION public.ctable1_20220912 FOR VALUES IN ('20220912');


--
-- Name: ctable1_20220913; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource1 ATTACH PARTITION public.ctable1_20220913 FOR VALUES IN ('20220913');


--
-- Name: ctable2_20221109; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20221109 FOR VALUES FROM ('2022-11-08 16:00:00+00') TO ('2022-11-09 16:00:00+00');


--
-- Name: ctable2_20221110; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20221110 FOR VALUES FROM ('2022-11-09 16:00:00+00') TO ('2022-11-10 16:00:00+00');


--
-- Name: ctable2_20221114; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20221114 FOR VALUES FROM ('2022-11-13 16:00:00+00') TO ('2022-11-14 16:00:00+00');


--
-- Name: ctable2_20221118; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20221118 FOR VALUES FROM ('2022-11-17 16:00:00+00') TO ('2022-11-18 16:00:00+00');


--
-- Name: ctable2_20221211; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20221211 FOR VALUES FROM ('2022-12-10 16:00:00+00') TO ('2022-12-11 16:00:00+00');


--
-- Name: ctable2_20230119; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230119 FOR VALUES FROM ('2023-01-18 16:00:00+00') TO ('2023-01-19 16:00:00+00');


--
-- Name: ctable2_20230120; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230120 FOR VALUES FROM ('2023-01-19 16:00:00+00') TO ('2023-01-20 16:00:00+00');


--
-- Name: ctable2_20230121; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230121 FOR VALUES FROM ('2023-01-20 16:00:00+00') TO ('2023-01-21 16:00:00+00');


--
-- Name: ctable2_20230122; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230122 FOR VALUES FROM ('2023-01-21 16:00:00+00') TO ('2023-01-22 16:00:00+00');


--
-- Name: ctable2_20230210; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230210 FOR VALUES FROM ('2023-02-09 16:00:00+00') TO ('2023-02-10 16:00:00+00');


--
-- Name: ctable2_20230211; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230211 FOR VALUES FROM ('2023-02-10 16:00:00+00') TO ('2023-02-11 16:00:00+00');


--
-- Name: ctable2_20230212; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230212 FOR VALUES FROM ('2023-02-11 16:00:00+00') TO ('2023-02-12 16:00:00+00');


--
-- Name: ctable2_20230213; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230213 FOR VALUES FROM ('2023-02-12 16:00:00+00') TO ('2023-02-13 16:00:00+00');


--
-- Name: ctable2_20230214; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230214 FOR VALUES FROM ('2023-02-13 16:00:00+00') TO ('2023-02-14 16:00:00+00');


--
-- Name: ctable2_20230215; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230215 FOR VALUES FROM ('2023-02-14 16:00:00+00') TO ('2023-02-15 16:00:00+00');


--
-- Name: ctable2_20230423; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230423 FOR VALUES FROM ('2023-04-22 16:00:00+00') TO ('2023-04-23 16:00:00+00');


--
-- Name: ctable2_20230424; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230424 FOR VALUES FROM ('2023-04-23 16:00:00+00') TO ('2023-04-24 16:00:00+00');


--
-- Name: ctable2_20230425; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230425 FOR VALUES FROM ('2023-04-24 16:00:00+00') TO ('2023-04-25 16:00:00+00');


--
-- Name: ctable2_20230426; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230426 FOR VALUES FROM ('2023-04-25 16:00:00+00') TO ('2023-04-26 16:00:00+00');


--
-- Name: ctable2_20230427; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230427 FOR VALUES FROM ('2023-04-26 16:00:00+00') TO ('2023-04-27 16:00:00+00');


--
-- Name: ctable2_20230428; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230428 FOR VALUES FROM ('2023-04-27 16:00:00+00') TO ('2023-04-28 16:00:00+00');


--
-- Name: ctable2_20230609; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230609 FOR VALUES FROM ('2023-06-08 16:00:00+00') TO ('2023-06-09 16:00:00+00');


--
-- Name: ctable2_20230610; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230610 FOR VALUES FROM ('2023-06-09 16:00:00+00') TO ('2023-06-10 16:00:00+00');


--
-- Name: ctable2_20230912; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230912 FOR VALUES FROM ('2023-09-11 16:00:00+00') TO ('2023-09-12 16:00:00+00');


--
-- Name: ctable2_20230913; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230913 FOR VALUES FROM ('2023-09-12 16:00:00+00') TO ('2023-09-13 16:00:00+00');


--
-- Name: ctable2_20230914; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230914 FOR VALUES FROM ('2023-09-13 16:00:00+00') TO ('2023-09-14 16:00:00+00');


--
-- Name: ctable2_20230915; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230915 FOR VALUES FROM ('2023-09-14 16:00:00+00') TO ('2023-09-15 16:00:00+00');


--
-- Name: ctable2_20230916; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230916 FOR VALUES FROM ('2023-09-15 16:00:00+00') TO ('2023-09-16 16:00:00+00');


--
-- Name: ctable2_20230917; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230917 FOR VALUES FROM ('2023-09-16 16:00:00+00') TO ('2023-09-17 16:00:00+00');


--
-- Name: ctable2_20230918; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20230918 FOR VALUES FROM ('2023-09-17 16:00:00+00') TO ('2023-09-18 16:00:00+00');


--
-- Name: ctable2_20231118; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20231118 FOR VALUES FROM ('2023-11-17 16:00:00+00') TO ('2023-11-18 16:00:00+00');


--
-- Name: ctable2_20231119; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20231119 FOR VALUES FROM ('2023-11-18 16:00:00+00') TO ('2023-11-19 16:00:00+00');


--
-- Name: ctable2_20231120; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20231120 FOR VALUES FROM ('2023-11-19 16:00:00+00') TO ('2023-11-20 16:00:00+00');


--
-- Name: ctable2_20231121; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20231121 FOR VALUES FROM ('2023-11-20 16:00:00+00') TO ('2023-11-21 16:00:00+00');


--
-- Name: ctable2_20231122; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20231122 FOR VALUES FROM ('2023-11-21 16:00:00+00') TO ('2023-11-22 16:00:00+00');


--
-- Name: ctable2_20231123; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20231123 FOR VALUES FROM ('2023-11-22 16:00:00+00') TO ('2023-11-23 16:00:00+00');


--
-- Name: ctable2_20231124; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20231124 FOR VALUES FROM ('2023-11-23 16:00:00+00') TO ('2023-11-24 16:00:00+00');


--
-- Name: ctable2_20240213; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20240213 FOR VALUES FROM ('2024-02-12 16:00:00+00') TO ('2024-02-13 16:00:00+00');


--
-- Name: ctable2_20240214; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20240214 FOR VALUES FROM ('2024-02-13 16:00:00+00') TO ('2024-02-14 16:00:00+00');


--
-- Name: ctable2_20240215; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20240215 FOR VALUES FROM ('2024-02-14 16:00:00+00') TO ('2024-02-15 16:00:00+00');


--
-- Name: ctable2_20240216; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20240216 FOR VALUES FROM ('2024-02-15 16:00:00+00') TO ('2024-02-16 16:00:00+00');


--
-- Name: ctable2_20240217; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20240217 FOR VALUES FROM ('2024-02-16 16:00:00+00') TO ('2024-02-17 16:00:00+00');


--
-- Name: ctable2_20240218; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20240218 FOR VALUES FROM ('2024-02-17 16:00:00+00') TO ('2024-02-18 16:00:00+00');


--
-- Name: ctable2_20240219; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20240219 FOR VALUES FROM ('2024-02-18 16:00:00+00') TO ('2024-02-19 16:00:00+00');


--
-- Name: ctable2_20250225; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250225 FOR VALUES FROM ('2025-02-25 00:00:00+00') TO ('2025-02-26 00:00:00+00');


--
-- Name: ctable2_20250226; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250226 FOR VALUES FROM ('2025-02-26 00:00:00+00') TO ('2025-02-27 00:00:00+00');


--
-- Name: ctable2_20250227; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250227 FOR VALUES FROM ('2025-02-27 00:00:00+00') TO ('2025-02-28 00:00:00+00');


--
-- Name: ctable2_20250228; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250228 FOR VALUES FROM ('2025-02-28 00:00:00+00') TO ('2025-03-01 00:00:00+00');


--
-- Name: ctable2_20250314; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250314 FOR VALUES FROM ('2025-03-14 00:00:00+00') TO ('2025-03-15 00:00:00+00');


--
-- Name: ctable2_20250315; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250315 FOR VALUES FROM ('2025-03-15 00:00:00+00') TO ('2025-03-16 00:00:00+00');


--
-- Name: ctable2_20250316; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250316 FOR VALUES FROM ('2025-03-16 00:00:00+00') TO ('2025-03-17 00:00:00+00');


--
-- Name: ctable2_20250317; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250317 FOR VALUES FROM ('2025-03-17 00:00:00+00') TO ('2025-03-18 00:00:00+00');


--
-- Name: ctable2_20250318; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250318 FOR VALUES FROM ('2025-03-18 00:00:00+00') TO ('2025-03-19 00:00:00+00');


--
-- Name: ctable2_20250319; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250319 FOR VALUES FROM ('2025-03-19 00:00:00+00') TO ('2025-03-20 00:00:00+00');


--
-- Name: ctable2_20250320; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250320 FOR VALUES FROM ('2025-03-20 00:00:00+00') TO ('2025-03-21 00:00:00+00');


--
-- Name: ctable2_20250506; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250506 FOR VALUES FROM ('2025-05-06 00:00:00+00') TO ('2025-05-07 00:00:00+00');


--
-- Name: ctable2_20250507; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250507 FOR VALUES FROM ('2025-05-07 00:00:00+00') TO ('2025-05-08 00:00:00+00');


--
-- Name: ctable2_20250710; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250710 FOR VALUES FROM ('2025-07-10 00:00:00+00') TO ('2025-07-11 00:00:00+00');


--
-- Name: ctable2_20250711; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250711 FOR VALUES FROM ('2025-07-11 00:00:00+00') TO ('2025-07-12 00:00:00+00');


--
-- Name: ctable2_20250712; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250712 FOR VALUES FROM ('2025-07-12 00:00:00+00') TO ('2025-07-13 00:00:00+00');


--
-- Name: ctable2_20250713; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250713 FOR VALUES FROM ('2025-07-13 00:00:00+00') TO ('2025-07-14 00:00:00+00');


--
-- Name: ctable2_20250828; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250828 FOR VALUES FROM ('2025-08-28 00:00:00+00') TO ('2025-08-29 00:00:00+00');


--
-- Name: ctable2_20250829; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250829 FOR VALUES FROM ('2025-08-29 00:00:00+00') TO ('2025-08-30 00:00:00+00');


--
-- Name: ctable2_20250830; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250830 FOR VALUES FROM ('2025-08-30 00:00:00+00') TO ('2025-08-31 00:00:00+00');


--
-- Name: ctable2_20250831; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250831 FOR VALUES FROM ('2025-08-31 00:00:00+00') TO ('2025-09-01 00:00:00+00');


--
-- Name: ctable2_20250901; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250901 FOR VALUES FROM ('2025-09-01 00:00:00+00') TO ('2025-09-02 00:00:00+00');


--
-- Name: ctable2_20250902; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250902 FOR VALUES FROM ('2025-09-02 00:00:00+00') TO ('2025-09-03 00:00:00+00');


--
-- Name: ctable2_20250903; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20250903 FOR VALUES FROM ('2025-09-03 00:00:00+00') TO ('2025-09-04 00:00:00+00');


--
-- Name: ctable2_20260102; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20260102 FOR VALUES FROM ('2026-01-02 00:00:00+00') TO ('2026-01-03 00:00:00+00');


--
-- Name: ctable2_20260103; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20260103 FOR VALUES FROM ('2026-01-03 00:00:00+00') TO ('2026-01-04 00:00:00+00');


--
-- Name: ctable2_20260104; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20260104 FOR VALUES FROM ('2026-01-04 00:00:00+00') TO ('2026-01-05 00:00:00+00');


--
-- Name: ctable2_20260105; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20260105 FOR VALUES FROM ('2026-01-05 00:00:00+00') TO ('2026-01-06 00:00:00+00');


--
-- Name: ctable2_20260106; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20260106 FOR VALUES FROM ('2026-01-06 00:00:00+00') TO ('2026-01-07 00:00:00+00');


--
-- Name: ctable2_20260107; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20260107 FOR VALUES FROM ('2026-01-07 00:00:00+00') TO ('2026-01-08 00:00:00+00');


--
-- Name: ctable2_20260108; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource2 ATTACH PARTITION public.ctable2_20260108 FOR VALUES FROM ('2026-01-08 00:00:00+00') TO ('2026-01-09 00:00:00+00');


--
-- Name: ctable_2022_09_06_17; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_06_17 FOR VALUES FROM ('2022-09-06 09:00:00+00') TO ('2022-09-06 09:59:59.99+00');


--
-- Name: ctable_2022_09_06_18; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_06_18 FOR VALUES FROM ('2022-09-06 10:00:00+00') TO ('2022-09-06 10:59:59.99+00');


--
-- Name: ctable_2022_09_06_19; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_06_19 FOR VALUES FROM ('2022-09-06 11:00:00+00') TO ('2022-09-06 11:59:59.99+00');


--
-- Name: ctable_2022_09_06_20; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_06_20 FOR VALUES FROM ('2022-09-06 12:00:00+00') TO ('2022-09-06 12:59:59.99+00');


--
-- Name: ctable_2022_09_06_21; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_06_21 FOR VALUES FROM ('2022-09-06 13:00:00+00') TO ('2022-09-06 13:59:59.99+00');


--
-- Name: ctable_2022_09_06_22; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_06_22 FOR VALUES FROM ('2022-09-06 14:00:00+00') TO ('2022-09-06 14:59:59.99+00');


--
-- Name: ctable_2022_09_06_23; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_06_23 FOR VALUES FROM ('2022-09-06 15:00:00+00') TO ('2022-09-06 15:59:59.99+00');


--
-- Name: ctable_2022_09_07_00; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_07_00 FOR VALUES FROM ('2022-09-06 16:00:00+00') TO ('2022-09-06 16:59:59.99+00');


--
-- Name: ctable_2022_09_07_01; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_07_01 FOR VALUES FROM ('2022-09-06 17:00:00+00') TO ('2022-09-06 17:59:59.99+00');


--
-- Name: ctable_2022_09_07_02; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_07_02 FOR VALUES FROM ('2022-09-06 18:00:00+00') TO ('2022-09-06 18:59:59.99+00');


--
-- Name: ctable_2022_09_07_12; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_07_12 FOR VALUES FROM ('2022-09-07 04:00:00+00') TO ('2022-09-07 04:59:59.99+00');


--
-- Name: ctable_2022_09_07_14; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_07_14 FOR VALUES FROM ('2022-09-07 06:00:00+00') TO ('2022-09-07 06:59:59.99+00');


--
-- Name: ctable_2022_09_07_15; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_07_15 FOR VALUES FROM ('2022-09-07 07:00:00+00') TO ('2022-09-07 07:59:59.99+00');


--
-- Name: ctable_2022_09_07_16; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_07_16 FOR VALUES FROM ('2022-09-07 08:00:00+00') TO ('2022-09-07 08:59:59.99+00');


--
-- Name: ctable_2022_09_07_17; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_07_17 FOR VALUES FROM ('2022-09-07 09:00:00+00') TO ('2022-09-07 09:59:59.99+00');


--
-- Name: ctable_2022_09_07_18; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_07_18 FOR VALUES FROM ('2022-09-07 10:00:00+00') TO ('2022-09-07 10:59:59.99+00');


--
-- Name: ctable_2022_09_07_19; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_07_19 FOR VALUES FROM ('2022-09-07 11:00:00+00') TO ('2022-09-07 11:59:59.99+00');


--
-- Name: ctable_2022_09_07_20; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_07_20 FOR VALUES FROM ('2022-09-07 12:00:00+00') TO ('2022-09-07 12:59:59.99+00');


--
-- Name: ctable_2022_09_07_21; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_07_21 FOR VALUES FROM ('2022-09-07 13:00:00+00') TO ('2022-09-07 13:59:59.99+00');


--
-- Name: ctable_2022_09_07_22; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_07_22 FOR VALUES FROM ('2022-09-07 14:00:00+00') TO ('2022-09-07 14:59:59.99+00');


--
-- Name: ctable_2022_09_07_23; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_07_23 FOR VALUES FROM ('2022-09-07 15:00:00+00') TO ('2022-09-07 15:59:59.99+00');


--
-- Name: ctable_2022_09_08_00; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_00 FOR VALUES FROM ('2022-09-07 16:00:00+00') TO ('2022-09-07 16:59:59.99+00');


--
-- Name: ctable_2022_09_08_01; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_01 FOR VALUES FROM ('2022-09-07 17:00:00+00') TO ('2022-09-07 17:59:59.99+00');


--
-- Name: ctable_2022_09_08_02; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_02 FOR VALUES FROM ('2022-09-07 18:00:00+00') TO ('2022-09-07 18:59:59.99+00');


--
-- Name: ctable_2022_09_08_03; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_03 FOR VALUES FROM ('2022-09-07 19:00:00+00') TO ('2022-09-07 19:59:59.99+00');


--
-- Name: ctable_2022_09_08_04; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_04 FOR VALUES FROM ('2022-09-07 20:00:00+00') TO ('2022-09-07 20:59:59.99+00');


--
-- Name: ctable_2022_09_08_05; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_05 FOR VALUES FROM ('2022-09-07 21:00:00+00') TO ('2022-09-07 21:59:59.99+00');


--
-- Name: ctable_2022_09_08_06; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_06 FOR VALUES FROM ('2022-09-07 22:00:00+00') TO ('2022-09-07 22:59:59.99+00');


--
-- Name: ctable_2022_09_08_07; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_07 FOR VALUES FROM ('2022-09-07 23:00:00+00') TO ('2022-09-07 23:59:59.99+00');


--
-- Name: ctable_2022_09_08_08; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_08 FOR VALUES FROM ('2022-09-08 00:00:00+00') TO ('2022-09-08 00:59:59.99+00');


--
-- Name: ctable_2022_09_08_09; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_09 FOR VALUES FROM ('2022-09-08 01:00:00+00') TO ('2022-09-08 01:59:59.99+00');


--
-- Name: ctable_2022_09_08_10; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_10 FOR VALUES FROM ('2022-09-08 02:00:00+00') TO ('2022-09-08 02:59:59.99+00');


--
-- Name: ctable_2022_09_08_11; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_11 FOR VALUES FROM ('2022-09-08 03:00:00+00') TO ('2022-09-08 03:59:59.99+00');


--
-- Name: ctable_2022_09_08_12; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_12 FOR VALUES FROM ('2022-09-08 04:00:00+00') TO ('2022-09-08 04:59:59.99+00');


--
-- Name: ctable_2022_09_08_13; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_13 FOR VALUES FROM ('2022-09-08 05:00:00+00') TO ('2022-09-08 05:59:59.99+00');


--
-- Name: ctable_2022_09_08_14; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_14 FOR VALUES FROM ('2022-09-08 06:00:00+00') TO ('2022-09-08 06:59:59.99+00');


--
-- Name: ctable_2022_09_08_15; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_15 FOR VALUES FROM ('2022-09-08 07:00:00+00') TO ('2022-09-08 07:59:59.99+00');


--
-- Name: ctable_2022_09_08_16; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_16 FOR VALUES FROM ('2022-09-08 08:00:00+00') TO ('2022-09-08 08:59:59.99+00');


--
-- Name: ctable_2022_09_08_17; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_17 FOR VALUES FROM ('2022-09-08 09:00:00+00') TO ('2022-09-08 09:59:59.99+00');


--
-- Name: ctable_2022_09_08_18; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_18 FOR VALUES FROM ('2022-09-08 10:00:00+00') TO ('2022-09-08 10:59:59.99+00');


--
-- Name: ctable_2022_09_08_19; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_19 FOR VALUES FROM ('2022-09-08 11:00:00+00') TO ('2022-09-08 11:59:59.99+00');


--
-- Name: ctable_2022_09_08_20; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_20 FOR VALUES FROM ('2022-09-08 12:00:00+00') TO ('2022-09-08 12:59:59.99+00');


--
-- Name: ctable_2022_09_08_21; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_21 FOR VALUES FROM ('2022-09-08 13:00:00+00') TO ('2022-09-08 13:59:59.99+00');


--
-- Name: ctable_2022_09_08_22; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_22 FOR VALUES FROM ('2022-09-08 14:00:00+00') TO ('2022-09-08 14:59:59.99+00');


--
-- Name: ctable_2022_09_08_23; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_08_23 FOR VALUES FROM ('2022-09-08 15:00:00+00') TO ('2022-09-08 15:59:59.99+00');


--
-- Name: ctable_2022_09_09_00; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_00 FOR VALUES FROM ('2022-09-08 16:00:00+00') TO ('2022-09-08 16:59:59.99+00');


--
-- Name: ctable_2022_09_09_01; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_01 FOR VALUES FROM ('2022-09-08 17:00:00+00') TO ('2022-09-08 17:59:59.99+00');


--
-- Name: ctable_2022_09_09_02; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_02 FOR VALUES FROM ('2022-09-08 18:00:00+00') TO ('2022-09-08 18:59:59.99+00');


--
-- Name: ctable_2022_09_09_03; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_03 FOR VALUES FROM ('2022-09-08 19:00:00+00') TO ('2022-09-08 19:59:59.99+00');


--
-- Name: ctable_2022_09_09_04; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_04 FOR VALUES FROM ('2022-09-08 20:00:00+00') TO ('2022-09-08 20:59:59.99+00');


--
-- Name: ctable_2022_09_09_05; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_05 FOR VALUES FROM ('2022-09-08 21:00:00+00') TO ('2022-09-08 21:59:59.99+00');


--
-- Name: ctable_2022_09_09_06; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_06 FOR VALUES FROM ('2022-09-08 22:00:00+00') TO ('2022-09-08 22:59:59.99+00');


--
-- Name: ctable_2022_09_09_07; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_07 FOR VALUES FROM ('2022-09-08 23:00:00+00') TO ('2022-09-08 23:59:59.99+00');


--
-- Name: ctable_2022_09_09_08; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_08 FOR VALUES FROM ('2022-09-09 00:00:00+00') TO ('2022-09-09 00:59:59.99+00');


--
-- Name: ctable_2022_09_09_09; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_09 FOR VALUES FROM ('2022-09-09 01:00:00+00') TO ('2022-09-09 01:59:59.99+00');


--
-- Name: ctable_2022_09_09_10; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_10 FOR VALUES FROM ('2022-09-09 02:00:00+00') TO ('2022-09-09 02:59:59.99+00');


--
-- Name: ctable_2022_09_09_11; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_11 FOR VALUES FROM ('2022-09-09 03:00:00+00') TO ('2022-09-09 03:59:59.99+00');


--
-- Name: ctable_2022_09_09_12; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_12 FOR VALUES FROM ('2022-09-09 04:00:00+00') TO ('2022-09-09 04:59:59.99+00');


--
-- Name: ctable_2022_09_09_13; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_13 FOR VALUES FROM ('2022-09-09 05:00:00+00') TO ('2022-09-09 05:59:59.99+00');


--
-- Name: ctable_2022_09_09_14; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_14 FOR VALUES FROM ('2022-09-09 06:00:00+00') TO ('2022-09-09 06:59:59.99+00');


--
-- Name: ctable_2022_09_09_15; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_15 FOR VALUES FROM ('2022-09-09 07:00:00+00') TO ('2022-09-09 07:59:59.99+00');


--
-- Name: ctable_2022_09_09_16; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_16 FOR VALUES FROM ('2022-09-09 08:00:00+00') TO ('2022-09-09 08:59:59.99+00');


--
-- Name: ctable_2022_09_09_17; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_17 FOR VALUES FROM ('2022-09-09 09:00:00+00') TO ('2022-09-09 09:59:59.99+00');


--
-- Name: ctable_2022_09_09_18; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_18 FOR VALUES FROM ('2022-09-09 10:00:00+00') TO ('2022-09-09 10:59:59.99+00');


--
-- Name: ctable_2022_09_09_19; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_19 FOR VALUES FROM ('2022-09-09 11:00:00+00') TO ('2022-09-09 11:59:59.99+00');


--
-- Name: ctable_2022_09_09_20; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_20 FOR VALUES FROM ('2022-09-09 12:00:00+00') TO ('2022-09-09 12:59:59.99+00');


--
-- Name: ctable_2022_09_09_21; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_21 FOR VALUES FROM ('2022-09-09 13:00:00+00') TO ('2022-09-09 13:59:59.99+00');


--
-- Name: ctable_2022_09_09_22; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_22 FOR VALUES FROM ('2022-09-09 14:00:00+00') TO ('2022-09-09 14:59:59.99+00');


--
-- Name: ctable_2022_09_09_23; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_09_23 FOR VALUES FROM ('2022-09-09 15:00:00+00') TO ('2022-09-09 15:59:59.99+00');


--
-- Name: ctable_2022_09_10_00; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_00 FOR VALUES FROM ('2022-09-09 16:00:00+00') TO ('2022-09-09 16:59:59.99+00');


--
-- Name: ctable_2022_09_10_01; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_01 FOR VALUES FROM ('2022-09-09 17:00:00+00') TO ('2022-09-09 17:59:59.99+00');


--
-- Name: ctable_2022_09_10_02; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_02 FOR VALUES FROM ('2022-09-09 18:00:00+00') TO ('2022-09-09 18:59:59.99+00');


--
-- Name: ctable_2022_09_10_03; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_03 FOR VALUES FROM ('2022-09-09 19:00:00+00') TO ('2022-09-09 19:59:59.99+00');


--
-- Name: ctable_2022_09_10_04; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_04 FOR VALUES FROM ('2022-09-09 20:00:00+00') TO ('2022-09-09 20:59:59.99+00');


--
-- Name: ctable_2022_09_10_05; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_05 FOR VALUES FROM ('2022-09-09 21:00:00+00') TO ('2022-09-09 21:59:59.99+00');


--
-- Name: ctable_2022_09_10_06; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_06 FOR VALUES FROM ('2022-09-09 22:00:00+00') TO ('2022-09-09 22:59:59.99+00');


--
-- Name: ctable_2022_09_10_07; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_07 FOR VALUES FROM ('2022-09-09 23:00:00+00') TO ('2022-09-09 23:59:59.99+00');


--
-- Name: ctable_2022_09_10_08; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_08 FOR VALUES FROM ('2022-09-10 00:00:00+00') TO ('2022-09-10 00:59:59.99+00');


--
-- Name: ctable_2022_09_10_09; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_09 FOR VALUES FROM ('2022-09-10 01:00:00+00') TO ('2022-09-10 01:59:59.99+00');


--
-- Name: ctable_2022_09_10_10; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_10 FOR VALUES FROM ('2022-09-10 02:00:00+00') TO ('2022-09-10 02:59:59.99+00');


--
-- Name: ctable_2022_09_10_11; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_11 FOR VALUES FROM ('2022-09-10 03:00:00+00') TO ('2022-09-10 03:59:59.99+00');


--
-- Name: ctable_2022_09_10_12; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_12 FOR VALUES FROM ('2022-09-10 04:00:00+00') TO ('2022-09-10 04:59:59.99+00');


--
-- Name: ctable_2022_09_10_13; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_13 FOR VALUES FROM ('2022-09-10 05:00:00+00') TO ('2022-09-10 05:59:59.99+00');


--
-- Name: ctable_2022_09_10_14; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_14 FOR VALUES FROM ('2022-09-10 06:00:00+00') TO ('2022-09-10 06:59:59.99+00');


--
-- Name: ctable_2022_09_10_15; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_15 FOR VALUES FROM ('2022-09-10 07:00:00+00') TO ('2022-09-10 07:59:59.99+00');


--
-- Name: ctable_2022_09_10_16; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_16 FOR VALUES FROM ('2022-09-10 08:00:00+00') TO ('2022-09-10 08:59:59.99+00');


--
-- Name: ctable_2022_09_10_17; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_17 FOR VALUES FROM ('2022-09-10 09:00:00+00') TO ('2022-09-10 09:59:59.99+00');


--
-- Name: ctable_2022_09_10_18; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_18 FOR VALUES FROM ('2022-09-10 10:00:00+00') TO ('2022-09-10 10:59:59.99+00');


--
-- Name: ctable_2022_09_10_19; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_19 FOR VALUES FROM ('2022-09-10 11:00:00+00') TO ('2022-09-10 11:59:59.99+00');


--
-- Name: ctable_2022_09_10_20; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_20 FOR VALUES FROM ('2022-09-10 12:00:00+00') TO ('2022-09-10 12:59:59.99+00');


--
-- Name: ctable_2022_09_10_21; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_21 FOR VALUES FROM ('2022-09-10 13:00:00+00') TO ('2022-09-10 13:59:59.99+00');


--
-- Name: ctable_2022_09_10_22; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_22 FOR VALUES FROM ('2022-09-10 14:00:00+00') TO ('2022-09-10 14:59:59.99+00');


--
-- Name: ctable_2022_09_10_23; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_10_23 FOR VALUES FROM ('2022-09-10 15:00:00+00') TO ('2022-09-10 15:59:59.99+00');


--
-- Name: ctable_2022_09_11_00; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_00 FOR VALUES FROM ('2022-09-10 16:00:00+00') TO ('2022-09-10 16:59:59.99+00');


--
-- Name: ctable_2022_09_11_01; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_01 FOR VALUES FROM ('2022-09-10 17:00:00+00') TO ('2022-09-10 17:59:59.99+00');


--
-- Name: ctable_2022_09_11_02; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_02 FOR VALUES FROM ('2022-09-10 18:00:00+00') TO ('2022-09-10 18:59:59.99+00');


--
-- Name: ctable_2022_09_11_03; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_03 FOR VALUES FROM ('2022-09-10 19:00:00+00') TO ('2022-09-10 19:59:59.99+00');


--
-- Name: ctable_2022_09_11_04; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_04 FOR VALUES FROM ('2022-09-10 20:00:00+00') TO ('2022-09-10 20:59:59.99+00');


--
-- Name: ctable_2022_09_11_05; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_05 FOR VALUES FROM ('2022-09-10 21:00:00+00') TO ('2022-09-10 21:59:59.99+00');


--
-- Name: ctable_2022_09_11_06; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_06 FOR VALUES FROM ('2022-09-10 22:00:00+00') TO ('2022-09-10 22:59:59.99+00');


--
-- Name: ctable_2022_09_11_07; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_07 FOR VALUES FROM ('2022-09-10 23:00:00+00') TO ('2022-09-10 23:59:59.99+00');


--
-- Name: ctable_2022_09_11_08; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_08 FOR VALUES FROM ('2022-09-11 00:00:00+00') TO ('2022-09-11 00:59:59.99+00');


--
-- Name: ctable_2022_09_11_09; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_09 FOR VALUES FROM ('2022-09-11 01:00:00+00') TO ('2022-09-11 01:59:59.99+00');


--
-- Name: ctable_2022_09_11_10; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_10 FOR VALUES FROM ('2022-09-11 02:00:00+00') TO ('2022-09-11 02:59:59.99+00');


--
-- Name: ctable_2022_09_11_11; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_11 FOR VALUES FROM ('2022-09-11 03:00:00+00') TO ('2022-09-11 03:59:59.99+00');


--
-- Name: ctable_2022_09_11_12; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_12 FOR VALUES FROM ('2022-09-11 04:00:00+00') TO ('2022-09-11 04:59:59.99+00');


--
-- Name: ctable_2022_09_11_13; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_13 FOR VALUES FROM ('2022-09-11 05:00:00+00') TO ('2022-09-11 05:59:59.99+00');


--
-- Name: ctable_2022_09_11_14; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_14 FOR VALUES FROM ('2022-09-11 06:00:00+00') TO ('2022-09-11 06:59:59.99+00');


--
-- Name: ctable_2022_09_11_15; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_15 FOR VALUES FROM ('2022-09-11 07:00:00+00') TO ('2022-09-11 07:59:59.99+00');


--
-- Name: ctable_2022_09_11_16; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_16 FOR VALUES FROM ('2022-09-11 08:00:00+00') TO ('2022-09-11 08:59:59.99+00');


--
-- Name: ctable_2022_09_11_17; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_17 FOR VALUES FROM ('2022-09-11 09:00:00+00') TO ('2022-09-11 09:59:59.99+00');


--
-- Name: ctable_2022_09_11_18; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_18 FOR VALUES FROM ('2022-09-11 10:00:00+00') TO ('2022-09-11 10:59:59.99+00');


--
-- Name: ctable_2022_09_11_19; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_19 FOR VALUES FROM ('2022-09-11 11:00:00+00') TO ('2022-09-11 11:59:59.99+00');


--
-- Name: ctable_2022_09_11_20; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_20 FOR VALUES FROM ('2022-09-11 12:00:00+00') TO ('2022-09-11 12:59:59.99+00');


--
-- Name: ctable_2022_09_11_21; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_21 FOR VALUES FROM ('2022-09-11 13:00:00+00') TO ('2022-09-11 13:59:59.99+00');


--
-- Name: ctable_2022_09_11_22; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_22 FOR VALUES FROM ('2022-09-11 14:00:00+00') TO ('2022-09-11 14:59:59.99+00');


--
-- Name: ctable_2022_09_11_23; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_11_23 FOR VALUES FROM ('2022-09-11 15:00:00+00') TO ('2022-09-11 15:59:59.99+00');


--
-- Name: ctable_2022_09_12_00; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_12_00 FOR VALUES FROM ('2022-09-11 16:00:00+00') TO ('2022-09-11 16:59:59.99+00');


--
-- Name: ctable_2022_09_12_01; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_12_01 FOR VALUES FROM ('2022-09-11 17:00:00+00') TO ('2022-09-11 17:59:59.99+00');


--
-- Name: ctable_2022_09_12_02; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_12_02 FOR VALUES FROM ('2022-09-11 18:00:00+00') TO ('2022-09-11 18:59:59.99+00');


--
-- Name: ctable_2022_09_12_03; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_12_03 FOR VALUES FROM ('2022-09-11 19:00:00+00') TO ('2022-09-11 19:59:59.99+00');


--
-- Name: ctable_2022_09_12_11; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.container_resource ATTACH PARTITION public.ctable_2022_09_12_11 FOR VALUES FROM ('2022-09-12 03:00:00+00') TO ('2022-09-12 03:59:59.99+00');


--
-- Name: ntable1_20220910; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource1 ATTACH PARTITION public.ntable1_20220910 FOR VALUES IN ('20220910');


--
-- Name: ntable1_20220912; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource1 ATTACH PARTITION public.ntable1_20220912 FOR VALUES IN ('20220912');


--
-- Name: ntable1_20220913; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource1 ATTACH PARTITION public.ntable1_20220913 FOR VALUES IN ('20220913');


--
-- Name: ntable2_20221108; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20221108 FOR VALUES FROM ('2022-11-07 16:00:00+00') TO ('2022-11-08 16:00:00+00');


--
-- Name: ntable2_20221109; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20221109 FOR VALUES FROM ('2022-11-08 16:00:00+00') TO ('2022-11-09 16:00:00+00');


--
-- Name: ntable2_20221110; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20221110 FOR VALUES FROM ('2022-11-09 16:00:00+00') TO ('2022-11-10 16:00:00+00');


--
-- Name: ntable2_20221114; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20221114 FOR VALUES FROM ('2022-11-13 16:00:00+00') TO ('2022-11-14 16:00:00+00');


--
-- Name: ntable2_20221118; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20221118 FOR VALUES FROM ('2022-11-17 16:00:00+00') TO ('2022-11-18 16:00:00+00');


--
-- Name: ntable2_20221211; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20221211 FOR VALUES FROM ('2022-12-10 16:00:00+00') TO ('2022-12-11 16:00:00+00');


--
-- Name: ntable2_20230119; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230119 FOR VALUES FROM ('2023-01-18 16:00:00+00') TO ('2023-01-19 16:00:00+00');


--
-- Name: ntable2_20230120; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230120 FOR VALUES FROM ('2023-01-19 16:00:00+00') TO ('2023-01-20 16:00:00+00');


--
-- Name: ntable2_20230121; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230121 FOR VALUES FROM ('2023-01-20 16:00:00+00') TO ('2023-01-21 16:00:00+00');


--
-- Name: ntable2_20230122; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230122 FOR VALUES FROM ('2023-01-21 16:00:00+00') TO ('2023-01-22 16:00:00+00');


--
-- Name: ntable2_20230210; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230210 FOR VALUES FROM ('2023-02-09 16:00:00+00') TO ('2023-02-10 16:00:00+00');


--
-- Name: ntable2_20230211; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230211 FOR VALUES FROM ('2023-02-10 16:00:00+00') TO ('2023-02-11 16:00:00+00');


--
-- Name: ntable2_20230212; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230212 FOR VALUES FROM ('2023-02-11 16:00:00+00') TO ('2023-02-12 16:00:00+00');


--
-- Name: ntable2_20230213; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230213 FOR VALUES FROM ('2023-02-12 16:00:00+00') TO ('2023-02-13 16:00:00+00');


--
-- Name: ntable2_20230214; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230214 FOR VALUES FROM ('2023-02-13 16:00:00+00') TO ('2023-02-14 16:00:00+00');


--
-- Name: ntable2_20230215; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230215 FOR VALUES FROM ('2023-02-14 16:00:00+00') TO ('2023-02-15 16:00:00+00');


--
-- Name: ntable2_20230423; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230423 FOR VALUES FROM ('2023-04-22 16:00:00+00') TO ('2023-04-23 16:00:00+00');


--
-- Name: ntable2_20230424; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230424 FOR VALUES FROM ('2023-04-23 16:00:00+00') TO ('2023-04-24 16:00:00+00');


--
-- Name: ntable2_20230425; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230425 FOR VALUES FROM ('2023-04-24 16:00:00+00') TO ('2023-04-25 16:00:00+00');


--
-- Name: ntable2_20230426; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230426 FOR VALUES FROM ('2023-04-25 16:00:00+00') TO ('2023-04-26 16:00:00+00');


--
-- Name: ntable2_20230427; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230427 FOR VALUES FROM ('2023-04-26 16:00:00+00') TO ('2023-04-27 16:00:00+00');


--
-- Name: ntable2_20230428; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230428 FOR VALUES FROM ('2023-04-27 16:00:00+00') TO ('2023-04-28 16:00:00+00');


--
-- Name: ntable2_20230609; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230609 FOR VALUES FROM ('2023-06-08 16:00:00+00') TO ('2023-06-09 16:00:00+00');


--
-- Name: ntable2_20230610; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230610 FOR VALUES FROM ('2023-06-09 16:00:00+00') TO ('2023-06-10 16:00:00+00');


--
-- Name: ntable2_20230912; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230912 FOR VALUES FROM ('2023-09-11 16:00:00+00') TO ('2023-09-12 16:00:00+00');


--
-- Name: ntable2_20230913; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230913 FOR VALUES FROM ('2023-09-12 16:00:00+00') TO ('2023-09-13 16:00:00+00');


--
-- Name: ntable2_20230914; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230914 FOR VALUES FROM ('2023-09-13 16:00:00+00') TO ('2023-09-14 16:00:00+00');


--
-- Name: ntable2_20230915; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230915 FOR VALUES FROM ('2023-09-14 16:00:00+00') TO ('2023-09-15 16:00:00+00');


--
-- Name: ntable2_20230916; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230916 FOR VALUES FROM ('2023-09-15 16:00:00+00') TO ('2023-09-16 16:00:00+00');


--
-- Name: ntable2_20230917; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230917 FOR VALUES FROM ('2023-09-16 16:00:00+00') TO ('2023-09-17 16:00:00+00');


--
-- Name: ntable2_20230918; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20230918 FOR VALUES FROM ('2023-09-17 16:00:00+00') TO ('2023-09-18 16:00:00+00');


--
-- Name: ntable2_20231118; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20231118 FOR VALUES FROM ('2023-11-17 16:00:00+00') TO ('2023-11-18 16:00:00+00');


--
-- Name: ntable2_20231119; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20231119 FOR VALUES FROM ('2023-11-18 16:00:00+00') TO ('2023-11-19 16:00:00+00');


--
-- Name: ntable2_20231120; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20231120 FOR VALUES FROM ('2023-11-19 16:00:00+00') TO ('2023-11-20 16:00:00+00');


--
-- Name: ntable2_20231121; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20231121 FOR VALUES FROM ('2023-11-20 16:00:00+00') TO ('2023-11-21 16:00:00+00');


--
-- Name: ntable2_20231122; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20231122 FOR VALUES FROM ('2023-11-21 16:00:00+00') TO ('2023-11-22 16:00:00+00');


--
-- Name: ntable2_20231123; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20231123 FOR VALUES FROM ('2023-11-22 16:00:00+00') TO ('2023-11-23 16:00:00+00');


--
-- Name: ntable2_20231124; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20231124 FOR VALUES FROM ('2023-11-23 16:00:00+00') TO ('2023-11-24 16:00:00+00');


--
-- Name: ntable2_20240213; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20240213 FOR VALUES FROM ('2024-02-12 16:00:00+00') TO ('2024-02-13 16:00:00+00');


--
-- Name: ntable2_20240214; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20240214 FOR VALUES FROM ('2024-02-13 16:00:00+00') TO ('2024-02-14 16:00:00+00');


--
-- Name: ntable2_20240215; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20240215 FOR VALUES FROM ('2024-02-14 16:00:00+00') TO ('2024-02-15 16:00:00+00');


--
-- Name: ntable2_20240216; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20240216 FOR VALUES FROM ('2024-02-15 16:00:00+00') TO ('2024-02-16 16:00:00+00');


--
-- Name: ntable2_20240217; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20240217 FOR VALUES FROM ('2024-02-16 16:00:00+00') TO ('2024-02-17 16:00:00+00');


--
-- Name: ntable2_20240218; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20240218 FOR VALUES FROM ('2024-02-17 16:00:00+00') TO ('2024-02-18 16:00:00+00');


--
-- Name: ntable2_20240219; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20240219 FOR VALUES FROM ('2024-02-18 16:00:00+00') TO ('2024-02-19 16:00:00+00');


--
-- Name: ntable2_20250225; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250225 FOR VALUES FROM ('2025-02-25 00:00:00+00') TO ('2025-02-26 00:00:00+00');


--
-- Name: ntable2_20250226; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250226 FOR VALUES FROM ('2025-02-26 00:00:00+00') TO ('2025-02-27 00:00:00+00');


--
-- Name: ntable2_20250227; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250227 FOR VALUES FROM ('2025-02-27 00:00:00+00') TO ('2025-02-28 00:00:00+00');


--
-- Name: ntable2_20250228; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250228 FOR VALUES FROM ('2025-02-28 00:00:00+00') TO ('2025-03-01 00:00:00+00');


--
-- Name: ntable2_20250314; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250314 FOR VALUES FROM ('2025-03-14 00:00:00+00') TO ('2025-03-15 00:00:00+00');


--
-- Name: ntable2_20250315; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250315 FOR VALUES FROM ('2025-03-15 00:00:00+00') TO ('2025-03-16 00:00:00+00');


--
-- Name: ntable2_20250316; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250316 FOR VALUES FROM ('2025-03-16 00:00:00+00') TO ('2025-03-17 00:00:00+00');


--
-- Name: ntable2_20250317; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250317 FOR VALUES FROM ('2025-03-17 00:00:00+00') TO ('2025-03-18 00:00:00+00');


--
-- Name: ntable2_20250318; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250318 FOR VALUES FROM ('2025-03-18 00:00:00+00') TO ('2025-03-19 00:00:00+00');


--
-- Name: ntable2_20250319; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250319 FOR VALUES FROM ('2025-03-19 00:00:00+00') TO ('2025-03-20 00:00:00+00');


--
-- Name: ntable2_20250320; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250320 FOR VALUES FROM ('2025-03-20 00:00:00+00') TO ('2025-03-21 00:00:00+00');


--
-- Name: ntable2_20250506; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250506 FOR VALUES FROM ('2025-05-06 00:00:00+00') TO ('2025-05-07 00:00:00+00');


--
-- Name: ntable2_20250507; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250507 FOR VALUES FROM ('2025-05-07 00:00:00+00') TO ('2025-05-08 00:00:00+00');


--
-- Name: ntable2_20250710; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250710 FOR VALUES FROM ('2025-07-10 00:00:00+00') TO ('2025-07-11 00:00:00+00');


--
-- Name: ntable2_20250711; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250711 FOR VALUES FROM ('2025-07-11 00:00:00+00') TO ('2025-07-12 00:00:00+00');


--
-- Name: ntable2_20250712; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250712 FOR VALUES FROM ('2025-07-12 00:00:00+00') TO ('2025-07-13 00:00:00+00');


--
-- Name: ntable2_20250713; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250713 FOR VALUES FROM ('2025-07-13 00:00:00+00') TO ('2025-07-14 00:00:00+00');


--
-- Name: ntable2_20250828; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250828 FOR VALUES FROM ('2025-08-28 00:00:00+00') TO ('2025-08-29 00:00:00+00');


--
-- Name: ntable2_20250829; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250829 FOR VALUES FROM ('2025-08-29 00:00:00+00') TO ('2025-08-30 00:00:00+00');


--
-- Name: ntable2_20250830; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250830 FOR VALUES FROM ('2025-08-30 00:00:00+00') TO ('2025-08-31 00:00:00+00');


--
-- Name: ntable2_20250831; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250831 FOR VALUES FROM ('2025-08-31 00:00:00+00') TO ('2025-09-01 00:00:00+00');


--
-- Name: ntable2_20250901; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250901 FOR VALUES FROM ('2025-09-01 00:00:00+00') TO ('2025-09-02 00:00:00+00');


--
-- Name: ntable2_20250902; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250902 FOR VALUES FROM ('2025-09-02 00:00:00+00') TO ('2025-09-03 00:00:00+00');


--
-- Name: ntable2_20250903; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20250903 FOR VALUES FROM ('2025-09-03 00:00:00+00') TO ('2025-09-04 00:00:00+00');


--
-- Name: ntable2_20260102; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20260102 FOR VALUES FROM ('2026-01-02 00:00:00+00') TO ('2026-01-03 00:00:00+00');


--
-- Name: ntable2_20260103; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20260103 FOR VALUES FROM ('2026-01-03 00:00:00+00') TO ('2026-01-04 00:00:00+00');


--
-- Name: ntable2_20260104; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20260104 FOR VALUES FROM ('2026-01-04 00:00:00+00') TO ('2026-01-05 00:00:00+00');


--
-- Name: ntable2_20260105; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20260105 FOR VALUES FROM ('2026-01-05 00:00:00+00') TO ('2026-01-06 00:00:00+00');


--
-- Name: ntable2_20260106; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20260106 FOR VALUES FROM ('2026-01-06 00:00:00+00') TO ('2026-01-07 00:00:00+00');


--
-- Name: ntable2_20260107; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20260107 FOR VALUES FROM ('2026-01-07 00:00:00+00') TO ('2026-01-08 00:00:00+00');


--
-- Name: ntable2_20260108; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource2 ATTACH PARTITION public.ntable2_20260108 FOR VALUES FROM ('2026-01-08 00:00:00+00') TO ('2026-01-09 00:00:00+00');


--
-- Name: ntable_2022_09_06_23; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_06_23 FOR VALUES FROM ('2022-09-06 15:00:00+00') TO ('2022-09-06 15:59:59.99+00');


--
-- Name: ntable_2022_09_07_00; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_07_00 FOR VALUES FROM ('2022-09-06 16:00:00+00') TO ('2022-09-06 16:59:59.99+00');


--
-- Name: ntable_2022_09_07_01; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_07_01 FOR VALUES FROM ('2022-09-06 17:00:00+00') TO ('2022-09-06 17:59:59.99+00');


--
-- Name: ntable_2022_09_07_02; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_07_02 FOR VALUES FROM ('2022-09-06 18:00:00+00') TO ('2022-09-06 18:59:59.99+00');


--
-- Name: ntable_2022_09_07_12; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_07_12 FOR VALUES FROM ('2022-09-07 04:00:00+00') TO ('2022-09-07 04:59:59.99+00');


--
-- Name: ntable_2022_09_07_14; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_07_14 FOR VALUES FROM ('2022-09-07 06:00:00+00') TO ('2022-09-07 06:59:59.99+00');


--
-- Name: ntable_2022_09_07_15; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_07_15 FOR VALUES FROM ('2022-09-07 07:00:00+00') TO ('2022-09-07 07:59:59.99+00');


--
-- Name: ntable_2022_09_07_16; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_07_16 FOR VALUES FROM ('2022-09-07 08:00:00+00') TO ('2022-09-07 08:59:59.99+00');


--
-- Name: ntable_2022_09_07_17; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_07_17 FOR VALUES FROM ('2022-09-07 09:00:00+00') TO ('2022-09-07 09:59:59.99+00');


--
-- Name: ntable_2022_09_07_18; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_07_18 FOR VALUES FROM ('2022-09-07 10:00:00+00') TO ('2022-09-07 10:59:59.99+00');


--
-- Name: ntable_2022_09_07_19; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_07_19 FOR VALUES FROM ('2022-09-07 11:00:00+00') TO ('2022-09-07 11:59:59.99+00');


--
-- Name: ntable_2022_09_07_20; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_07_20 FOR VALUES FROM ('2022-09-07 12:00:00+00') TO ('2022-09-07 12:59:59.99+00');


--
-- Name: ntable_2022_09_07_21; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_07_21 FOR VALUES FROM ('2022-09-07 13:00:00+00') TO ('2022-09-07 13:59:59.99+00');


--
-- Name: ntable_2022_09_07_22; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_07_22 FOR VALUES FROM ('2022-09-07 14:00:00+00') TO ('2022-09-07 14:59:59.99+00');


--
-- Name: ntable_2022_09_07_23; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_07_23 FOR VALUES FROM ('2022-09-07 15:00:00+00') TO ('2022-09-07 15:59:59.99+00');


--
-- Name: ntable_2022_09_08_00; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_00 FOR VALUES FROM ('2022-09-07 16:00:00+00') TO ('2022-09-07 16:59:59.99+00');


--
-- Name: ntable_2022_09_08_01; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_01 FOR VALUES FROM ('2022-09-07 17:00:00+00') TO ('2022-09-07 17:59:59.99+00');


--
-- Name: ntable_2022_09_08_02; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_02 FOR VALUES FROM ('2022-09-07 18:00:00+00') TO ('2022-09-07 18:59:59.99+00');


--
-- Name: ntable_2022_09_08_03; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_03 FOR VALUES FROM ('2022-09-07 19:00:00+00') TO ('2022-09-07 19:59:59.99+00');


--
-- Name: ntable_2022_09_08_04; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_04 FOR VALUES FROM ('2022-09-07 20:00:00+00') TO ('2022-09-07 20:59:59.99+00');


--
-- Name: ntable_2022_09_08_05; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_05 FOR VALUES FROM ('2022-09-07 21:00:00+00') TO ('2022-09-07 21:59:59.99+00');


--
-- Name: ntable_2022_09_08_06; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_06 FOR VALUES FROM ('2022-09-07 22:00:00+00') TO ('2022-09-07 22:59:59.99+00');


--
-- Name: ntable_2022_09_08_07; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_07 FOR VALUES FROM ('2022-09-07 23:00:00+00') TO ('2022-09-07 23:59:59.99+00');


--
-- Name: ntable_2022_09_08_08; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_08 FOR VALUES FROM ('2022-09-08 00:00:00+00') TO ('2022-09-08 00:59:59.99+00');


--
-- Name: ntable_2022_09_08_09; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_09 FOR VALUES FROM ('2022-09-08 01:00:00+00') TO ('2022-09-08 01:59:59.99+00');


--
-- Name: ntable_2022_09_08_10; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_10 FOR VALUES FROM ('2022-09-08 02:00:00+00') TO ('2022-09-08 02:59:59.99+00');


--
-- Name: ntable_2022_09_08_11; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_11 FOR VALUES FROM ('2022-09-08 03:00:00+00') TO ('2022-09-08 03:59:59.99+00');


--
-- Name: ntable_2022_09_08_12; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_12 FOR VALUES FROM ('2022-09-08 04:00:00+00') TO ('2022-09-08 04:59:59.99+00');


--
-- Name: ntable_2022_09_08_13; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_13 FOR VALUES FROM ('2022-09-08 05:00:00+00') TO ('2022-09-08 05:59:59.99+00');


--
-- Name: ntable_2022_09_08_14; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_14 FOR VALUES FROM ('2022-09-08 06:00:00+00') TO ('2022-09-08 06:59:59.99+00');


--
-- Name: ntable_2022_09_08_15; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_15 FOR VALUES FROM ('2022-09-08 07:00:00+00') TO ('2022-09-08 07:59:59.99+00');


--
-- Name: ntable_2022_09_08_16; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_16 FOR VALUES FROM ('2022-09-08 08:00:00+00') TO ('2022-09-08 08:59:59.99+00');


--
-- Name: ntable_2022_09_08_17; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_17 FOR VALUES FROM ('2022-09-08 09:00:00+00') TO ('2022-09-08 09:59:59.99+00');


--
-- Name: ntable_2022_09_08_18; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_18 FOR VALUES FROM ('2022-09-08 10:00:00+00') TO ('2022-09-08 10:59:59.99+00');


--
-- Name: ntable_2022_09_08_19; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_19 FOR VALUES FROM ('2022-09-08 11:00:00+00') TO ('2022-09-08 11:59:59.99+00');


--
-- Name: ntable_2022_09_08_20; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_20 FOR VALUES FROM ('2022-09-08 12:00:00+00') TO ('2022-09-08 12:59:59.99+00');


--
-- Name: ntable_2022_09_08_21; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_21 FOR VALUES FROM ('2022-09-08 13:00:00+00') TO ('2022-09-08 13:59:59.99+00');


--
-- Name: ntable_2022_09_08_22; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_22 FOR VALUES FROM ('2022-09-08 14:00:00+00') TO ('2022-09-08 14:59:59.99+00');


--
-- Name: ntable_2022_09_08_23; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_08_23 FOR VALUES FROM ('2022-09-08 15:00:00+00') TO ('2022-09-08 15:59:59.99+00');


--
-- Name: ntable_2022_09_09_00; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_00 FOR VALUES FROM ('2022-09-08 16:00:00+00') TO ('2022-09-08 16:59:59.99+00');


--
-- Name: ntable_2022_09_09_01; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_01 FOR VALUES FROM ('2022-09-08 17:00:00+00') TO ('2022-09-08 17:59:59.99+00');


--
-- Name: ntable_2022_09_09_02; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_02 FOR VALUES FROM ('2022-09-08 18:00:00+00') TO ('2022-09-08 18:59:59.99+00');


--
-- Name: ntable_2022_09_09_03; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_03 FOR VALUES FROM ('2022-09-08 19:00:00+00') TO ('2022-09-08 19:59:59.99+00');


--
-- Name: ntable_2022_09_09_04; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_04 FOR VALUES FROM ('2022-09-08 20:00:00+00') TO ('2022-09-08 20:59:59.99+00');


--
-- Name: ntable_2022_09_09_05; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_05 FOR VALUES FROM ('2022-09-08 21:00:00+00') TO ('2022-09-08 21:59:59.99+00');


--
-- Name: ntable_2022_09_09_06; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_06 FOR VALUES FROM ('2022-09-08 22:00:00+00') TO ('2022-09-08 22:59:59.99+00');


--
-- Name: ntable_2022_09_09_07; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_07 FOR VALUES FROM ('2022-09-08 23:00:00+00') TO ('2022-09-08 23:59:59.99+00');


--
-- Name: ntable_2022_09_09_08; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_08 FOR VALUES FROM ('2022-09-09 00:00:00+00') TO ('2022-09-09 00:59:59.99+00');


--
-- Name: ntable_2022_09_09_09; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_09 FOR VALUES FROM ('2022-09-09 01:00:00+00') TO ('2022-09-09 01:59:59.99+00');


--
-- Name: ntable_2022_09_09_10; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_10 FOR VALUES FROM ('2022-09-09 02:00:00+00') TO ('2022-09-09 02:59:59.99+00');


--
-- Name: ntable_2022_09_09_11; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_11 FOR VALUES FROM ('2022-09-09 03:00:00+00') TO ('2022-09-09 03:59:59.99+00');


--
-- Name: ntable_2022_09_09_12; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_12 FOR VALUES FROM ('2022-09-09 04:00:00+00') TO ('2022-09-09 04:59:59.99+00');


--
-- Name: ntable_2022_09_09_13; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_13 FOR VALUES FROM ('2022-09-09 05:00:00+00') TO ('2022-09-09 05:59:59.99+00');


--
-- Name: ntable_2022_09_09_14; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_14 FOR VALUES FROM ('2022-09-09 06:00:00+00') TO ('2022-09-09 06:59:59.99+00');


--
-- Name: ntable_2022_09_09_15; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_15 FOR VALUES FROM ('2022-09-09 07:00:00+00') TO ('2022-09-09 07:59:59.99+00');


--
-- Name: ntable_2022_09_09_16; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_16 FOR VALUES FROM ('2022-09-09 08:00:00+00') TO ('2022-09-09 08:59:59.99+00');


--
-- Name: ntable_2022_09_09_17; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_17 FOR VALUES FROM ('2022-09-09 09:00:00+00') TO ('2022-09-09 09:59:59.99+00');


--
-- Name: ntable_2022_09_09_18; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_18 FOR VALUES FROM ('2022-09-09 10:00:00+00') TO ('2022-09-09 10:59:59.99+00');


--
-- Name: ntable_2022_09_09_19; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_19 FOR VALUES FROM ('2022-09-09 11:00:00+00') TO ('2022-09-09 11:59:59.99+00');


--
-- Name: ntable_2022_09_09_20; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_20 FOR VALUES FROM ('2022-09-09 12:00:00+00') TO ('2022-09-09 12:59:59.99+00');


--
-- Name: ntable_2022_09_09_21; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_21 FOR VALUES FROM ('2022-09-09 13:00:00+00') TO ('2022-09-09 13:59:59.99+00');


--
-- Name: ntable_2022_09_09_22; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_22 FOR VALUES FROM ('2022-09-09 14:00:00+00') TO ('2022-09-09 14:59:59.99+00');


--
-- Name: ntable_2022_09_09_23; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_09_23 FOR VALUES FROM ('2022-09-09 15:00:00+00') TO ('2022-09-09 15:59:59.99+00');


--
-- Name: ntable_2022_09_10_00; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_00 FOR VALUES FROM ('2022-09-09 16:00:00+00') TO ('2022-09-09 16:59:59.99+00');


--
-- Name: ntable_2022_09_10_01; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_01 FOR VALUES FROM ('2022-09-09 17:00:00+00') TO ('2022-09-09 17:59:59.99+00');


--
-- Name: ntable_2022_09_10_02; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_02 FOR VALUES FROM ('2022-09-09 18:00:00+00') TO ('2022-09-09 18:59:59.99+00');


--
-- Name: ntable_2022_09_10_03; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_03 FOR VALUES FROM ('2022-09-09 19:00:00+00') TO ('2022-09-09 19:59:59.99+00');


--
-- Name: ntable_2022_09_10_04; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_04 FOR VALUES FROM ('2022-09-09 20:00:00+00') TO ('2022-09-09 20:59:59.99+00');


--
-- Name: ntable_2022_09_10_05; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_05 FOR VALUES FROM ('2022-09-09 21:00:00+00') TO ('2022-09-09 21:59:59.99+00');


--
-- Name: ntable_2022_09_10_06; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_06 FOR VALUES FROM ('2022-09-09 22:00:00+00') TO ('2022-09-09 22:59:59.99+00');


--
-- Name: ntable_2022_09_10_07; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_07 FOR VALUES FROM ('2022-09-09 23:00:00+00') TO ('2022-09-09 23:59:59.99+00');


--
-- Name: ntable_2022_09_10_08; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_08 FOR VALUES FROM ('2022-09-10 00:00:00+00') TO ('2022-09-10 00:59:59.99+00');


--
-- Name: ntable_2022_09_10_09; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_09 FOR VALUES FROM ('2022-09-10 01:00:00+00') TO ('2022-09-10 01:59:59.99+00');


--
-- Name: ntable_2022_09_10_10; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_10 FOR VALUES FROM ('2022-09-10 02:00:00+00') TO ('2022-09-10 02:59:59.99+00');


--
-- Name: ntable_2022_09_10_11; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_11 FOR VALUES FROM ('2022-09-10 03:00:00+00') TO ('2022-09-10 03:59:59.99+00');


--
-- Name: ntable_2022_09_10_12; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_12 FOR VALUES FROM ('2022-09-10 04:00:00+00') TO ('2022-09-10 04:59:59.99+00');


--
-- Name: ntable_2022_09_10_13; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_13 FOR VALUES FROM ('2022-09-10 05:00:00+00') TO ('2022-09-10 05:59:59.99+00');


--
-- Name: ntable_2022_09_10_14; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_14 FOR VALUES FROM ('2022-09-10 06:00:00+00') TO ('2022-09-10 06:59:59.99+00');


--
-- Name: ntable_2022_09_10_15; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_15 FOR VALUES FROM ('2022-09-10 07:00:00+00') TO ('2022-09-10 07:59:59.99+00');


--
-- Name: ntable_2022_09_10_16; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_16 FOR VALUES FROM ('2022-09-10 08:00:00+00') TO ('2022-09-10 08:59:59.99+00');


--
-- Name: ntable_2022_09_10_17; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_17 FOR VALUES FROM ('2022-09-10 09:00:00+00') TO ('2022-09-10 09:59:59.99+00');


--
-- Name: ntable_2022_09_10_18; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_18 FOR VALUES FROM ('2022-09-10 10:00:00+00') TO ('2022-09-10 10:59:59.99+00');


--
-- Name: ntable_2022_09_10_19; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_19 FOR VALUES FROM ('2022-09-10 11:00:00+00') TO ('2022-09-10 11:59:59.99+00');


--
-- Name: ntable_2022_09_10_20; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_20 FOR VALUES FROM ('2022-09-10 12:00:00+00') TO ('2022-09-10 12:59:59.99+00');


--
-- Name: ntable_2022_09_10_21; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_21 FOR VALUES FROM ('2022-09-10 13:00:00+00') TO ('2022-09-10 13:59:59.99+00');


--
-- Name: ntable_2022_09_10_22; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_22 FOR VALUES FROM ('2022-09-10 14:00:00+00') TO ('2022-09-10 14:59:59.99+00');


--
-- Name: ntable_2022_09_10_23; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_10_23 FOR VALUES FROM ('2022-09-10 15:00:00+00') TO ('2022-09-10 15:59:59.99+00');


--
-- Name: ntable_2022_09_11_00; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_00 FOR VALUES FROM ('2022-09-10 16:00:00+00') TO ('2022-09-10 16:59:59.99+00');


--
-- Name: ntable_2022_09_11_01; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_01 FOR VALUES FROM ('2022-09-10 17:00:00+00') TO ('2022-09-10 17:59:59.99+00');


--
-- Name: ntable_2022_09_11_02; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_02 FOR VALUES FROM ('2022-09-10 18:00:00+00') TO ('2022-09-10 18:59:59.99+00');


--
-- Name: ntable_2022_09_11_03; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_03 FOR VALUES FROM ('2022-09-10 19:00:00+00') TO ('2022-09-10 19:59:59.99+00');


--
-- Name: ntable_2022_09_11_04; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_04 FOR VALUES FROM ('2022-09-10 20:00:00+00') TO ('2022-09-10 20:59:59.99+00');


--
-- Name: ntable_2022_09_11_05; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_05 FOR VALUES FROM ('2022-09-10 21:00:00+00') TO ('2022-09-10 21:59:59.99+00');


--
-- Name: ntable_2022_09_11_06; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_06 FOR VALUES FROM ('2022-09-10 22:00:00+00') TO ('2022-09-10 22:59:59.99+00');


--
-- Name: ntable_2022_09_11_07; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_07 FOR VALUES FROM ('2022-09-10 23:00:00+00') TO ('2022-09-10 23:59:59.99+00');


--
-- Name: ntable_2022_09_11_08; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_08 FOR VALUES FROM ('2022-09-11 00:00:00+00') TO ('2022-09-11 00:59:59.99+00');


--
-- Name: ntable_2022_09_11_09; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_09 FOR VALUES FROM ('2022-09-11 01:00:00+00') TO ('2022-09-11 01:59:59.99+00');


--
-- Name: ntable_2022_09_11_10; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_10 FOR VALUES FROM ('2022-09-11 02:00:00+00') TO ('2022-09-11 02:59:59.99+00');


--
-- Name: ntable_2022_09_11_11; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_11 FOR VALUES FROM ('2022-09-11 03:00:00+00') TO ('2022-09-11 03:59:59.99+00');


--
-- Name: ntable_2022_09_11_12; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_12 FOR VALUES FROM ('2022-09-11 04:00:00+00') TO ('2022-09-11 04:59:59.99+00');


--
-- Name: ntable_2022_09_11_13; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_13 FOR VALUES FROM ('2022-09-11 05:00:00+00') TO ('2022-09-11 05:59:59.99+00');


--
-- Name: ntable_2022_09_11_14; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_14 FOR VALUES FROM ('2022-09-11 06:00:00+00') TO ('2022-09-11 06:59:59.99+00');


--
-- Name: ntable_2022_09_11_15; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_15 FOR VALUES FROM ('2022-09-11 07:00:00+00') TO ('2022-09-11 07:59:59.99+00');


--
-- Name: ntable_2022_09_11_16; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_16 FOR VALUES FROM ('2022-09-11 08:00:00+00') TO ('2022-09-11 08:59:59.99+00');


--
-- Name: ntable_2022_09_11_17; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_17 FOR VALUES FROM ('2022-09-11 09:00:00+00') TO ('2022-09-11 09:59:59.99+00');


--
-- Name: ntable_2022_09_11_18; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_18 FOR VALUES FROM ('2022-09-11 10:00:00+00') TO ('2022-09-11 10:59:59.99+00');


--
-- Name: ntable_2022_09_11_19; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_19 FOR VALUES FROM ('2022-09-11 11:00:00+00') TO ('2022-09-11 11:59:59.99+00');


--
-- Name: ntable_2022_09_11_20; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_20 FOR VALUES FROM ('2022-09-11 12:00:00+00') TO ('2022-09-11 12:59:59.99+00');


--
-- Name: ntable_2022_09_11_21; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_21 FOR VALUES FROM ('2022-09-11 13:00:00+00') TO ('2022-09-11 13:59:59.99+00');


--
-- Name: ntable_2022_09_11_22; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_22 FOR VALUES FROM ('2022-09-11 14:00:00+00') TO ('2022-09-11 14:59:59.99+00');


--
-- Name: ntable_2022_09_11_23; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_11_23 FOR VALUES FROM ('2022-09-11 15:00:00+00') TO ('2022-09-11 15:59:59.99+00');


--
-- Name: ntable_2022_09_12_00; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_12_00 FOR VALUES FROM ('2022-09-11 16:00:00+00') TO ('2022-09-11 16:59:59.99+00');


--
-- Name: ntable_2022_09_12_01; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_12_01 FOR VALUES FROM ('2022-09-11 17:00:00+00') TO ('2022-09-11 17:59:59.99+00');


--
-- Name: ntable_2022_09_12_02; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_12_02 FOR VALUES FROM ('2022-09-11 18:00:00+00') TO ('2022-09-11 18:59:59.99+00');


--
-- Name: ntable_2022_09_12_03; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_12_03 FOR VALUES FROM ('2022-09-11 19:00:00+00') TO ('2022-09-11 19:59:59.99+00');


--
-- Name: ntable_2022_09_12_11; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_resource ATTACH PARTITION public.ntable_2022_09_12_11 FOR VALUES FROM ('2022-09-12 03:00:00+00') TO ('2022-09-12 03:59:59.99+00');


--
-- Name: aaa aaa_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aaa
    ADD CONSTRAINT aaa_pkey PRIMARY KEY (s, f);


--
-- Name: node_list node_list_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.node_list
    ADD CONSTRAINT node_list_pkey PRIMARY KEY (node_id);


--
-- Name: partition_table1 partition_table1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partition_table1
    ADD CONSTRAINT partition_table1_pkey PRIMARY KEY (table_name);


--
-- Name: partition_table partition_table_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partition_table
    ADD CONSTRAINT partition_table_pkey PRIMARY KEY (table_name);


--
-- Name: test test_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test
    ADD CONSTRAINT test_pkey PRIMARY KEY (aid);


--
-- Name: cindex1_20220910; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex1_20220910 ON public.ctable1_20220910 USING btree (time_date);


--
-- Name: cindex1_20220912; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex1_20220912 ON public.ctable1_20220912 USING btree (time_date);


--
-- Name: cindex1_20220913; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex1_20220913 ON public.ctable1_20220913 USING btree (time_date);


--
-- Name: cindex2_20221108; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20221108 ON public.ctable2_20221108 USING btree ("time");


--
-- Name: cindex2_20221109; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20221109 ON public.ctable2_20221109 USING btree ("time");


--
-- Name: cindex2_20221110; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20221110 ON public.ctable2_20221110 USING btree ("time");


--
-- Name: cindex2_20221114; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20221114 ON public.ctable2_20221114 USING btree ("time");


--
-- Name: cindex2_20221118; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20221118 ON public.ctable2_20221118 USING btree ("time");


--
-- Name: cindex2_20221211; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20221211 ON public.ctable2_20221211 USING btree ("time");


--
-- Name: cindex2_20230119; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230119 ON public.ctable2_20230119 USING btree ("time");


--
-- Name: cindex2_20230120; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230120 ON public.ctable2_20230120 USING btree ("time");


--
-- Name: cindex2_20230121; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230121 ON public.ctable2_20230121 USING btree ("time");


--
-- Name: cindex2_20230122; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230122 ON public.ctable2_20230122 USING btree ("time");


--
-- Name: cindex2_20230210; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230210 ON public.ctable2_20230210 USING btree ("time");


--
-- Name: cindex2_20230211; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230211 ON public.ctable2_20230211 USING btree ("time");


--
-- Name: cindex2_20230212; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230212 ON public.ctable2_20230212 USING btree ("time");


--
-- Name: cindex2_20230213; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230213 ON public.ctable2_20230213 USING btree ("time");


--
-- Name: cindex2_20230214; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230214 ON public.ctable2_20230214 USING btree ("time");


--
-- Name: cindex2_20230215; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230215 ON public.ctable2_20230215 USING btree ("time");


--
-- Name: cindex2_20230423; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230423 ON public.ctable2_20230423 USING btree ("time");


--
-- Name: cindex2_20230424; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230424 ON public.ctable2_20230424 USING btree ("time");


--
-- Name: cindex2_20230425; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230425 ON public.ctable2_20230425 USING btree ("time");


--
-- Name: cindex2_20230426; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230426 ON public.ctable2_20230426 USING btree ("time");


--
-- Name: cindex2_20230427; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230427 ON public.ctable2_20230427 USING btree ("time");


--
-- Name: cindex2_20230428; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230428 ON public.ctable2_20230428 USING btree ("time");


--
-- Name: cindex2_20230609; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230609 ON public.ctable2_20230609 USING btree ("time");


--
-- Name: cindex2_20230610; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230610 ON public.ctable2_20230610 USING btree ("time");


--
-- Name: cindex2_20230912; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230912 ON public.ctable2_20230912 USING btree ("time");


--
-- Name: cindex2_20230913; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230913 ON public.ctable2_20230913 USING btree ("time");


--
-- Name: cindex2_20230914; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230914 ON public.ctable2_20230914 USING btree ("time");


--
-- Name: cindex2_20230915; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230915 ON public.ctable2_20230915 USING btree ("time");


--
-- Name: cindex2_20230916; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230916 ON public.ctable2_20230916 USING btree ("time");


--
-- Name: cindex2_20230917; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230917 ON public.ctable2_20230917 USING btree ("time");


--
-- Name: cindex2_20230918; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20230918 ON public.ctable2_20230918 USING btree ("time");


--
-- Name: cindex2_20231118; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20231118 ON public.ctable2_20231118 USING btree ("time");


--
-- Name: cindex2_20231119; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20231119 ON public.ctable2_20231119 USING btree ("time");


--
-- Name: cindex2_20231120; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20231120 ON public.ctable2_20231120 USING btree ("time");


--
-- Name: cindex2_20231121; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20231121 ON public.ctable2_20231121 USING btree ("time");


--
-- Name: cindex2_20231122; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20231122 ON public.ctable2_20231122 USING btree ("time");


--
-- Name: cindex2_20231123; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20231123 ON public.ctable2_20231123 USING btree ("time");


--
-- Name: cindex2_20231124; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20231124 ON public.ctable2_20231124 USING btree ("time");


--
-- Name: cindex2_20240213; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20240213 ON public.ctable2_20240213 USING btree ("time");


--
-- Name: cindex2_20240214; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20240214 ON public.ctable2_20240214 USING btree ("time");


--
-- Name: cindex2_20240215; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20240215 ON public.ctable2_20240215 USING btree ("time");


--
-- Name: cindex2_20240216; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20240216 ON public.ctable2_20240216 USING btree ("time");


--
-- Name: cindex2_20240217; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20240217 ON public.ctable2_20240217 USING btree ("time");


--
-- Name: cindex2_20240218; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20240218 ON public.ctable2_20240218 USING btree ("time");


--
-- Name: cindex2_20240219; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20240219 ON public.ctable2_20240219 USING btree ("time");


--
-- Name: cindex2_20250225; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250225 ON public.ctable2_20250225 USING btree ("time");


--
-- Name: cindex2_20250226; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250226 ON public.ctable2_20250226 USING btree ("time");


--
-- Name: cindex2_20250227; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250227 ON public.ctable2_20250227 USING btree ("time");


--
-- Name: cindex2_20250228; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250228 ON public.ctable2_20250228 USING btree ("time");


--
-- Name: cindex2_20250314; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250314 ON public.ctable2_20250314 USING btree ("time");


--
-- Name: cindex2_20250315; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250315 ON public.ctable2_20250315 USING btree ("time");


--
-- Name: cindex2_20250316; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250316 ON public.ctable2_20250316 USING btree ("time");


--
-- Name: cindex2_20250317; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250317 ON public.ctable2_20250317 USING btree ("time");


--
-- Name: cindex2_20250318; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250318 ON public.ctable2_20250318 USING btree ("time");


--
-- Name: cindex2_20250319; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250319 ON public.ctable2_20250319 USING btree ("time");


--
-- Name: cindex2_20250320; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250320 ON public.ctable2_20250320 USING btree ("time");


--
-- Name: cindex2_20250506; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250506 ON public.ctable2_20250506 USING btree ("time");


--
-- Name: cindex2_20250507; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250507 ON public.ctable2_20250507 USING btree ("time");


--
-- Name: cindex2_20250710; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250710 ON public.ctable2_20250710 USING btree ("time");


--
-- Name: cindex2_20250711; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250711 ON public.ctable2_20250711 USING btree ("time");


--
-- Name: cindex2_20250712; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250712 ON public.ctable2_20250712 USING btree ("time");


--
-- Name: cindex2_20250713; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250713 ON public.ctable2_20250713 USING btree ("time");


--
-- Name: cindex2_20250828; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250828 ON public.ctable2_20250828 USING btree ("time");


--
-- Name: cindex2_20250829; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250829 ON public.ctable2_20250829 USING btree ("time");


--
-- Name: cindex2_20250830; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250830 ON public.ctable2_20250830 USING btree ("time");


--
-- Name: cindex2_20250831; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250831 ON public.ctable2_20250831 USING btree ("time");


--
-- Name: cindex2_20250901; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250901 ON public.ctable2_20250901 USING btree ("time");


--
-- Name: cindex2_20250902; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250902 ON public.ctable2_20250902 USING btree ("time");


--
-- Name: cindex2_20250903; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20250903 ON public.ctable2_20250903 USING btree ("time");


--
-- Name: cindex2_20260102; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20260102 ON public.ctable2_20260102 USING btree ("time");


--
-- Name: cindex2_20260103; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20260103 ON public.ctable2_20260103 USING btree ("time");


--
-- Name: cindex2_20260104; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20260104 ON public.ctable2_20260104 USING btree ("time");


--
-- Name: cindex2_20260105; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20260105 ON public.ctable2_20260105 USING btree ("time");


--
-- Name: cindex2_20260106; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20260106 ON public.ctable2_20260106 USING btree ("time");


--
-- Name: cindex2_20260107; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20260107 ON public.ctable2_20260107 USING btree ("time");


--
-- Name: cindex2_20260108; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex2_20260108 ON public.ctable2_20260108 USING btree ("time");


--
-- Name: cindex_2022_09_06_17; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_06_17 ON public.ctable_2022_09_06_17 USING btree ("time");


--
-- Name: cindex_2022_09_06_18; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_06_18 ON public.ctable_2022_09_06_18 USING btree ("time");


--
-- Name: cindex_2022_09_06_19; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_06_19 ON public.ctable_2022_09_06_19 USING btree ("time");


--
-- Name: cindex_2022_09_06_20; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_06_20 ON public.ctable_2022_09_06_20 USING btree ("time");


--
-- Name: cindex_2022_09_06_21; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_06_21 ON public.ctable_2022_09_06_21 USING btree ("time");


--
-- Name: cindex_2022_09_06_22; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_06_22 ON public.ctable_2022_09_06_22 USING btree ("time");


--
-- Name: cindex_2022_09_06_23; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_06_23 ON public.ctable_2022_09_06_23 USING btree ("time");


--
-- Name: cindex_2022_09_07_00; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_07_00 ON public.ctable_2022_09_07_00 USING btree ("time");


--
-- Name: cindex_2022_09_07_01; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_07_01 ON public.ctable_2022_09_07_01 USING btree ("time");


--
-- Name: cindex_2022_09_07_02; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_07_02 ON public.ctable_2022_09_07_02 USING btree ("time");


--
-- Name: cindex_2022_09_07_12; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_07_12 ON public.ctable_2022_09_07_12 USING btree ("time");


--
-- Name: cindex_2022_09_07_14; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_07_14 ON public.ctable_2022_09_07_14 USING btree ("time");


--
-- Name: cindex_2022_09_07_15; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_07_15 ON public.ctable_2022_09_07_15 USING btree ("time");


--
-- Name: cindex_2022_09_07_16; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_07_16 ON public.ctable_2022_09_07_16 USING btree ("time");


--
-- Name: cindex_2022_09_07_17; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_07_17 ON public.ctable_2022_09_07_17 USING btree ("time");


--
-- Name: cindex_2022_09_07_18; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_07_18 ON public.ctable_2022_09_07_18 USING btree ("time");


--
-- Name: cindex_2022_09_07_19; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_07_19 ON public.ctable_2022_09_07_19 USING btree ("time");


--
-- Name: cindex_2022_09_07_20; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_07_20 ON public.ctable_2022_09_07_20 USING btree ("time");


--
-- Name: cindex_2022_09_07_21; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_07_21 ON public.ctable_2022_09_07_21 USING btree ("time");


--
-- Name: cindex_2022_09_07_22; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_07_22 ON public.ctable_2022_09_07_22 USING btree ("time");


--
-- Name: cindex_2022_09_07_23; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_07_23 ON public.ctable_2022_09_07_23 USING btree ("time");


--
-- Name: cindex_2022_09_08_00; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_00 ON public.ctable_2022_09_08_00 USING btree ("time");


--
-- Name: cindex_2022_09_08_01; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_01 ON public.ctable_2022_09_08_01 USING btree ("time");


--
-- Name: cindex_2022_09_08_02; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_02 ON public.ctable_2022_09_08_02 USING btree ("time");


--
-- Name: cindex_2022_09_08_03; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_03 ON public.ctable_2022_09_08_03 USING btree ("time");


--
-- Name: cindex_2022_09_08_04; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_04 ON public.ctable_2022_09_08_04 USING btree ("time");


--
-- Name: cindex_2022_09_08_05; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_05 ON public.ctable_2022_09_08_05 USING btree ("time");


--
-- Name: cindex_2022_09_08_06; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_06 ON public.ctable_2022_09_08_06 USING btree ("time");


--
-- Name: cindex_2022_09_08_07; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_07 ON public.ctable_2022_09_08_07 USING btree ("time");


--
-- Name: cindex_2022_09_08_08; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_08 ON public.ctable_2022_09_08_08 USING btree ("time");


--
-- Name: cindex_2022_09_08_09; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_09 ON public.ctable_2022_09_08_09 USING btree ("time");


--
-- Name: cindex_2022_09_08_10; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_10 ON public.ctable_2022_09_08_10 USING btree ("time");


--
-- Name: cindex_2022_09_08_11; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_11 ON public.ctable_2022_09_08_11 USING btree ("time");


--
-- Name: cindex_2022_09_08_12; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_12 ON public.ctable_2022_09_08_12 USING btree ("time");


--
-- Name: cindex_2022_09_08_13; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_13 ON public.ctable_2022_09_08_13 USING btree ("time");


--
-- Name: cindex_2022_09_08_14; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_14 ON public.ctable_2022_09_08_14 USING btree ("time");


--
-- Name: cindex_2022_09_08_15; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_15 ON public.ctable_2022_09_08_15 USING btree ("time");


--
-- Name: cindex_2022_09_08_16; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_16 ON public.ctable_2022_09_08_16 USING btree ("time");


--
-- Name: cindex_2022_09_08_17; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_17 ON public.ctable_2022_09_08_17 USING btree ("time");


--
-- Name: cindex_2022_09_08_18; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_18 ON public.ctable_2022_09_08_18 USING btree ("time");


--
-- Name: cindex_2022_09_08_19; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_19 ON public.ctable_2022_09_08_19 USING btree ("time");


--
-- Name: cindex_2022_09_08_20; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_20 ON public.ctable_2022_09_08_20 USING btree ("time");


--
-- Name: cindex_2022_09_08_21; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_21 ON public.ctable_2022_09_08_21 USING btree ("time");


--
-- Name: cindex_2022_09_08_22; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_22 ON public.ctable_2022_09_08_22 USING btree ("time");


--
-- Name: cindex_2022_09_08_23; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_08_23 ON public.ctable_2022_09_08_23 USING btree ("time");


--
-- Name: cindex_2022_09_09_00; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_00 ON public.ctable_2022_09_09_00 USING btree ("time");


--
-- Name: cindex_2022_09_09_01; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_01 ON public.ctable_2022_09_09_01 USING btree ("time");


--
-- Name: cindex_2022_09_09_02; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_02 ON public.ctable_2022_09_09_02 USING btree ("time");


--
-- Name: cindex_2022_09_09_03; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_03 ON public.ctable_2022_09_09_03 USING btree ("time");


--
-- Name: cindex_2022_09_09_04; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_04 ON public.ctable_2022_09_09_04 USING btree ("time");


--
-- Name: cindex_2022_09_09_05; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_05 ON public.ctable_2022_09_09_05 USING btree ("time");


--
-- Name: cindex_2022_09_09_06; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_06 ON public.ctable_2022_09_09_06 USING btree ("time");


--
-- Name: cindex_2022_09_09_07; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_07 ON public.ctable_2022_09_09_07 USING btree ("time");


--
-- Name: cindex_2022_09_09_08; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_08 ON public.ctable_2022_09_09_08 USING btree ("time");


--
-- Name: cindex_2022_09_09_09; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_09 ON public.ctable_2022_09_09_09 USING btree ("time");


--
-- Name: cindex_2022_09_09_10; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_10 ON public.ctable_2022_09_09_10 USING btree ("time");


--
-- Name: cindex_2022_09_09_11; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_11 ON public.ctable_2022_09_09_11 USING btree ("time");


--
-- Name: cindex_2022_09_09_12; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_12 ON public.ctable_2022_09_09_12 USING btree ("time");


--
-- Name: cindex_2022_09_09_13; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_13 ON public.ctable_2022_09_09_13 USING btree ("time");


--
-- Name: cindex_2022_09_09_14; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_14 ON public.ctable_2022_09_09_14 USING btree ("time");


--
-- Name: cindex_2022_09_09_15; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_15 ON public.ctable_2022_09_09_15 USING btree ("time");


--
-- Name: cindex_2022_09_09_16; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_16 ON public.ctable_2022_09_09_16 USING btree ("time");


--
-- Name: cindex_2022_09_09_17; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_17 ON public.ctable_2022_09_09_17 USING btree ("time");


--
-- Name: cindex_2022_09_09_18; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_18 ON public.ctable_2022_09_09_18 USING btree ("time");


--
-- Name: cindex_2022_09_09_19; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_19 ON public.ctable_2022_09_09_19 USING btree ("time");


--
-- Name: cindex_2022_09_09_20; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_20 ON public.ctable_2022_09_09_20 USING btree ("time");


--
-- Name: cindex_2022_09_09_21; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_21 ON public.ctable_2022_09_09_21 USING btree ("time");


--
-- Name: cindex_2022_09_09_22; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_22 ON public.ctable_2022_09_09_22 USING btree ("time");


--
-- Name: cindex_2022_09_09_23; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_09_23 ON public.ctable_2022_09_09_23 USING btree ("time");


--
-- Name: cindex_2022_09_10_00; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_00 ON public.ctable_2022_09_10_00 USING btree ("time");


--
-- Name: cindex_2022_09_10_01; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_01 ON public.ctable_2022_09_10_01 USING btree ("time");


--
-- Name: cindex_2022_09_10_02; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_02 ON public.ctable_2022_09_10_02 USING btree ("time");


--
-- Name: cindex_2022_09_10_03; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_03 ON public.ctable_2022_09_10_03 USING btree ("time");


--
-- Name: cindex_2022_09_10_04; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_04 ON public.ctable_2022_09_10_04 USING btree ("time");


--
-- Name: cindex_2022_09_10_05; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_05 ON public.ctable_2022_09_10_05 USING btree ("time");


--
-- Name: cindex_2022_09_10_06; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_06 ON public.ctable_2022_09_10_06 USING btree ("time");


--
-- Name: cindex_2022_09_10_07; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_07 ON public.ctable_2022_09_10_07 USING btree ("time");


--
-- Name: cindex_2022_09_10_08; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_08 ON public.ctable_2022_09_10_08 USING btree ("time");


--
-- Name: cindex_2022_09_10_09; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_09 ON public.ctable_2022_09_10_09 USING btree ("time");


--
-- Name: cindex_2022_09_10_10; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_10 ON public.ctable_2022_09_10_10 USING btree ("time");


--
-- Name: cindex_2022_09_10_11; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_11 ON public.ctable_2022_09_10_11 USING btree ("time");


--
-- Name: cindex_2022_09_10_12; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_12 ON public.ctable_2022_09_10_12 USING btree ("time");


--
-- Name: cindex_2022_09_10_13; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_13 ON public.ctable_2022_09_10_13 USING btree ("time");


--
-- Name: cindex_2022_09_10_14; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_14 ON public.ctable_2022_09_10_14 USING btree ("time");


--
-- Name: cindex_2022_09_10_15; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_15 ON public.ctable_2022_09_10_15 USING btree ("time");


--
-- Name: cindex_2022_09_10_16; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_16 ON public.ctable_2022_09_10_16 USING btree ("time");


--
-- Name: cindex_2022_09_10_17; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_17 ON public.ctable_2022_09_10_17 USING btree ("time");


--
-- Name: cindex_2022_09_10_18; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_18 ON public.ctable_2022_09_10_18 USING btree ("time");


--
-- Name: cindex_2022_09_10_19; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_19 ON public.ctable_2022_09_10_19 USING btree ("time");


--
-- Name: cindex_2022_09_10_20; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_20 ON public.ctable_2022_09_10_20 USING btree ("time");


--
-- Name: cindex_2022_09_10_21; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_21 ON public.ctable_2022_09_10_21 USING btree ("time");


--
-- Name: cindex_2022_09_10_22; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_22 ON public.ctable_2022_09_10_22 USING btree ("time");


--
-- Name: cindex_2022_09_10_23; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_10_23 ON public.ctable_2022_09_10_23 USING btree ("time");


--
-- Name: cindex_2022_09_11_00; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_00 ON public.ctable_2022_09_11_00 USING btree ("time");


--
-- Name: cindex_2022_09_11_01; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_01 ON public.ctable_2022_09_11_01 USING btree ("time");


--
-- Name: cindex_2022_09_11_02; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_02 ON public.ctable_2022_09_11_02 USING btree ("time");


--
-- Name: cindex_2022_09_11_03; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_03 ON public.ctable_2022_09_11_03 USING btree ("time");


--
-- Name: cindex_2022_09_11_04; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_04 ON public.ctable_2022_09_11_04 USING btree ("time");


--
-- Name: cindex_2022_09_11_05; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_05 ON public.ctable_2022_09_11_05 USING btree ("time");


--
-- Name: cindex_2022_09_11_06; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_06 ON public.ctable_2022_09_11_06 USING btree ("time");


--
-- Name: cindex_2022_09_11_07; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_07 ON public.ctable_2022_09_11_07 USING btree ("time");


--
-- Name: cindex_2022_09_11_08; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_08 ON public.ctable_2022_09_11_08 USING btree ("time");


--
-- Name: cindex_2022_09_11_09; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_09 ON public.ctable_2022_09_11_09 USING btree ("time");


--
-- Name: cindex_2022_09_11_10; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_10 ON public.ctable_2022_09_11_10 USING btree ("time");


--
-- Name: cindex_2022_09_11_11; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_11 ON public.ctable_2022_09_11_11 USING btree ("time");


--
-- Name: cindex_2022_09_11_12; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_12 ON public.ctable_2022_09_11_12 USING btree ("time");


--
-- Name: cindex_2022_09_11_13; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_13 ON public.ctable_2022_09_11_13 USING btree ("time");


--
-- Name: cindex_2022_09_11_14; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_14 ON public.ctable_2022_09_11_14 USING btree ("time");


--
-- Name: cindex_2022_09_11_15; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_15 ON public.ctable_2022_09_11_15 USING btree ("time");


--
-- Name: cindex_2022_09_11_16; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_16 ON public.ctable_2022_09_11_16 USING btree ("time");


--
-- Name: cindex_2022_09_11_17; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_17 ON public.ctable_2022_09_11_17 USING btree ("time");


--
-- Name: cindex_2022_09_11_18; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_18 ON public.ctable_2022_09_11_18 USING btree ("time");


--
-- Name: cindex_2022_09_11_19; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_19 ON public.ctable_2022_09_11_19 USING btree ("time");


--
-- Name: cindex_2022_09_11_20; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_20 ON public.ctable_2022_09_11_20 USING btree ("time");


--
-- Name: cindex_2022_09_11_21; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_21 ON public.ctable_2022_09_11_21 USING btree ("time");


--
-- Name: cindex_2022_09_11_22; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_22 ON public.ctable_2022_09_11_22 USING btree ("time");


--
-- Name: cindex_2022_09_11_23; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_11_23 ON public.ctable_2022_09_11_23 USING btree ("time");


--
-- Name: cindex_2022_09_12_00; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_12_00 ON public.ctable_2022_09_12_00 USING btree ("time");


--
-- Name: cindex_2022_09_12_01; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_12_01 ON public.ctable_2022_09_12_01 USING btree ("time");


--
-- Name: cindex_2022_09_12_02; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_12_02 ON public.ctable_2022_09_12_02 USING btree ("time");


--
-- Name: cindex_2022_09_12_03; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_12_03 ON public.ctable_2022_09_12_03 USING btree ("time");


--
-- Name: cindex_2022_09_12_11; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX cindex_2022_09_12_11 ON public.ctable_2022_09_12_11 USING btree ("time");


--
-- Name: nindex1_20220910; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex1_20220910 ON public.ntable1_20220910 USING btree (time_date);


--
-- Name: nindex1_20220912; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex1_20220912 ON public.ntable1_20220912 USING btree (time_date);


--
-- Name: nindex1_20220913; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex1_20220913 ON public.ntable1_20220913 USING btree (time_date);


--
-- Name: nindex2_20221108; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20221108 ON public.ntable2_20221108 USING btree ("time");


--
-- Name: nindex2_20221109; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20221109 ON public.ntable2_20221109 USING btree ("time");


--
-- Name: nindex2_20221110; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20221110 ON public.ntable2_20221110 USING btree ("time");


--
-- Name: nindex2_20221114; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20221114 ON public.ntable2_20221114 USING btree ("time");


--
-- Name: nindex2_20221118; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20221118 ON public.ntable2_20221118 USING btree ("time");


--
-- Name: nindex2_20221211; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20221211 ON public.ntable2_20221211 USING btree ("time");


--
-- Name: nindex2_20230119; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230119 ON public.ntable2_20230119 USING btree ("time");


--
-- Name: nindex2_20230120; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230120 ON public.ntable2_20230120 USING btree ("time");


--
-- Name: nindex2_20230121; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230121 ON public.ntable2_20230121 USING btree ("time");


--
-- Name: nindex2_20230122; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230122 ON public.ntable2_20230122 USING btree ("time");


--
-- Name: nindex2_20230210; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230210 ON public.ntable2_20230210 USING btree ("time");


--
-- Name: nindex2_20230211; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230211 ON public.ntable2_20230211 USING btree ("time");


--
-- Name: nindex2_20230212; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230212 ON public.ntable2_20230212 USING btree ("time");


--
-- Name: nindex2_20230213; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230213 ON public.ntable2_20230213 USING btree ("time");


--
-- Name: nindex2_20230214; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230214 ON public.ntable2_20230214 USING btree ("time");


--
-- Name: nindex2_20230215; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230215 ON public.ntable2_20230215 USING btree ("time");


--
-- Name: nindex2_20230423; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230423 ON public.ntable2_20230423 USING btree ("time");


--
-- Name: nindex2_20230424; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230424 ON public.ntable2_20230424 USING btree ("time");


--
-- Name: nindex2_20230425; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230425 ON public.ntable2_20230425 USING btree ("time");


--
-- Name: nindex2_20230426; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230426 ON public.ntable2_20230426 USING btree ("time");


--
-- Name: nindex2_20230427; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230427 ON public.ntable2_20230427 USING btree ("time");


--
-- Name: nindex2_20230428; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230428 ON public.ntable2_20230428 USING btree ("time");


--
-- Name: nindex2_20230609; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230609 ON public.ntable2_20230609 USING btree ("time");


--
-- Name: nindex2_20230610; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230610 ON public.ntable2_20230610 USING btree ("time");


--
-- Name: nindex2_20230912; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230912 ON public.ntable2_20230912 USING btree ("time");


--
-- Name: nindex2_20230913; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230913 ON public.ntable2_20230913 USING btree ("time");


--
-- Name: nindex2_20230914; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230914 ON public.ntable2_20230914 USING btree ("time");


--
-- Name: nindex2_20230915; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230915 ON public.ntable2_20230915 USING btree ("time");


--
-- Name: nindex2_20230916; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230916 ON public.ntable2_20230916 USING btree ("time");


--
-- Name: nindex2_20230917; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230917 ON public.ntable2_20230917 USING btree ("time");


--
-- Name: nindex2_20230918; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20230918 ON public.ntable2_20230918 USING btree ("time");


--
-- Name: nindex2_20231118; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20231118 ON public.ntable2_20231118 USING btree ("time");


--
-- Name: nindex2_20231119; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20231119 ON public.ntable2_20231119 USING btree ("time");


--
-- Name: nindex2_20231120; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20231120 ON public.ntable2_20231120 USING btree ("time");


--
-- Name: nindex2_20231121; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20231121 ON public.ntable2_20231121 USING btree ("time");


--
-- Name: nindex2_20231122; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20231122 ON public.ntable2_20231122 USING btree ("time");


--
-- Name: nindex2_20231123; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20231123 ON public.ntable2_20231123 USING btree ("time");


--
-- Name: nindex2_20231124; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20231124 ON public.ntable2_20231124 USING btree ("time");


--
-- Name: nindex2_20240213; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20240213 ON public.ntable2_20240213 USING btree ("time");


--
-- Name: nindex2_20240214; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20240214 ON public.ntable2_20240214 USING btree ("time");


--
-- Name: nindex2_20240215; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20240215 ON public.ntable2_20240215 USING btree ("time");


--
-- Name: nindex2_20240216; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20240216 ON public.ntable2_20240216 USING btree ("time");


--
-- Name: nindex2_20240217; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20240217 ON public.ntable2_20240217 USING btree ("time");


--
-- Name: nindex2_20240218; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20240218 ON public.ntable2_20240218 USING btree ("time");


--
-- Name: nindex2_20240219; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20240219 ON public.ntable2_20240219 USING btree ("time");


--
-- Name: nindex2_20250225; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250225 ON public.ntable2_20250225 USING btree ("time");


--
-- Name: nindex2_20250226; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250226 ON public.ntable2_20250226 USING btree ("time");


--
-- Name: nindex2_20250227; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250227 ON public.ntable2_20250227 USING btree ("time");


--
-- Name: nindex2_20250228; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250228 ON public.ntable2_20250228 USING btree ("time");


--
-- Name: nindex2_20250314; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250314 ON public.ntable2_20250314 USING btree ("time");


--
-- Name: nindex2_20250315; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250315 ON public.ntable2_20250315 USING btree ("time");


--
-- Name: nindex2_20250316; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250316 ON public.ntable2_20250316 USING btree ("time");


--
-- Name: nindex2_20250317; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250317 ON public.ntable2_20250317 USING btree ("time");


--
-- Name: nindex2_20250318; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250318 ON public.ntable2_20250318 USING btree ("time");


--
-- Name: nindex2_20250319; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250319 ON public.ntable2_20250319 USING btree ("time");


--
-- Name: nindex2_20250320; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250320 ON public.ntable2_20250320 USING btree ("time");


--
-- Name: nindex2_20250506; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250506 ON public.ntable2_20250506 USING btree ("time");


--
-- Name: nindex2_20250507; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250507 ON public.ntable2_20250507 USING btree ("time");


--
-- Name: nindex2_20250710; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250710 ON public.ntable2_20250710 USING btree ("time");


--
-- Name: nindex2_20250711; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250711 ON public.ntable2_20250711 USING btree ("time");


--
-- Name: nindex2_20250712; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250712 ON public.ntable2_20250712 USING btree ("time");


--
-- Name: nindex2_20250713; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250713 ON public.ntable2_20250713 USING btree ("time");


--
-- Name: nindex2_20250828; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250828 ON public.ntable2_20250828 USING btree ("time");


--
-- Name: nindex2_20250829; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250829 ON public.ntable2_20250829 USING btree ("time");


--
-- Name: nindex2_20250830; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250830 ON public.ntable2_20250830 USING btree ("time");


--
-- Name: nindex2_20250831; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250831 ON public.ntable2_20250831 USING btree ("time");


--
-- Name: nindex2_20250901; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250901 ON public.ntable2_20250901 USING btree ("time");


--
-- Name: nindex2_20250902; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250902 ON public.ntable2_20250902 USING btree ("time");


--
-- Name: nindex2_20250903; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20250903 ON public.ntable2_20250903 USING btree ("time");


--
-- Name: nindex2_20260102; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20260102 ON public.ntable2_20260102 USING btree ("time");


--
-- Name: nindex2_20260103; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20260103 ON public.ntable2_20260103 USING btree ("time");


--
-- Name: nindex2_20260104; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20260104 ON public.ntable2_20260104 USING btree ("time");


--
-- Name: nindex2_20260105; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20260105 ON public.ntable2_20260105 USING btree ("time");


--
-- Name: nindex2_20260106; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20260106 ON public.ntable2_20260106 USING btree ("time");


--
-- Name: nindex2_20260107; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20260107 ON public.ntable2_20260107 USING btree ("time");


--
-- Name: nindex2_20260108; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex2_20260108 ON public.ntable2_20260108 USING btree ("time");


--
-- Name: nindex_2022_09_06_23; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_06_23 ON public.ntable_2022_09_06_23 USING btree ("time");


--
-- Name: nindex_2022_09_07_00; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_07_00 ON public.ntable_2022_09_07_00 USING btree ("time");


--
-- Name: nindex_2022_09_07_01; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_07_01 ON public.ntable_2022_09_07_01 USING btree ("time");


--
-- Name: nindex_2022_09_07_02; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_07_02 ON public.ntable_2022_09_07_02 USING btree ("time");


--
-- Name: nindex_2022_09_07_12; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_07_12 ON public.ntable_2022_09_07_12 USING btree ("time");


--
-- Name: nindex_2022_09_07_14; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_07_14 ON public.ntable_2022_09_07_14 USING btree ("time");


--
-- Name: nindex_2022_09_07_15; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_07_15 ON public.ntable_2022_09_07_15 USING btree ("time");


--
-- Name: nindex_2022_09_07_16; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_07_16 ON public.ntable_2022_09_07_16 USING btree ("time");


--
-- Name: nindex_2022_09_07_17; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_07_17 ON public.ntable_2022_09_07_17 USING btree ("time");


--
-- Name: nindex_2022_09_07_18; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_07_18 ON public.ntable_2022_09_07_18 USING btree ("time");


--
-- Name: nindex_2022_09_07_19; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_07_19 ON public.ntable_2022_09_07_19 USING btree ("time");


--
-- Name: nindex_2022_09_07_20; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_07_20 ON public.ntable_2022_09_07_20 USING btree ("time");


--
-- Name: nindex_2022_09_07_21; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_07_21 ON public.ntable_2022_09_07_21 USING btree ("time");


--
-- Name: nindex_2022_09_07_22; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_07_22 ON public.ntable_2022_09_07_22 USING btree ("time");


--
-- Name: nindex_2022_09_07_23; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_07_23 ON public.ntable_2022_09_07_23 USING btree ("time");


--
-- Name: nindex_2022_09_08_00; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_00 ON public.ntable_2022_09_08_00 USING btree ("time");


--
-- Name: nindex_2022_09_08_01; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_01 ON public.ntable_2022_09_08_01 USING btree ("time");


--
-- Name: nindex_2022_09_08_02; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_02 ON public.ntable_2022_09_08_02 USING btree ("time");


--
-- Name: nindex_2022_09_08_03; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_03 ON public.ntable_2022_09_08_03 USING btree ("time");


--
-- Name: nindex_2022_09_08_04; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_04 ON public.ntable_2022_09_08_04 USING btree ("time");


--
-- Name: nindex_2022_09_08_05; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_05 ON public.ntable_2022_09_08_05 USING btree ("time");


--
-- Name: nindex_2022_09_08_06; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_06 ON public.ntable_2022_09_08_06 USING btree ("time");


--
-- Name: nindex_2022_09_08_07; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_07 ON public.ntable_2022_09_08_07 USING btree ("time");


--
-- Name: nindex_2022_09_08_08; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_08 ON public.ntable_2022_09_08_08 USING btree ("time");


--
-- Name: nindex_2022_09_08_09; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_09 ON public.ntable_2022_09_08_09 USING btree ("time");


--
-- Name: nindex_2022_09_08_10; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_10 ON public.ntable_2022_09_08_10 USING btree ("time");


--
-- Name: nindex_2022_09_08_11; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_11 ON public.ntable_2022_09_08_11 USING btree ("time");


--
-- Name: nindex_2022_09_08_12; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_12 ON public.ntable_2022_09_08_12 USING btree ("time");


--
-- Name: nindex_2022_09_08_13; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_13 ON public.ntable_2022_09_08_13 USING btree ("time");


--
-- Name: nindex_2022_09_08_14; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_14 ON public.ntable_2022_09_08_14 USING btree ("time");


--
-- Name: nindex_2022_09_08_15; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_15 ON public.ntable_2022_09_08_15 USING btree ("time");


--
-- Name: nindex_2022_09_08_16; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_16 ON public.ntable_2022_09_08_16 USING btree ("time");


--
-- Name: nindex_2022_09_08_17; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_17 ON public.ntable_2022_09_08_17 USING btree ("time");


--
-- Name: nindex_2022_09_08_18; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_18 ON public.ntable_2022_09_08_18 USING btree ("time");


--
-- Name: nindex_2022_09_08_19; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_19 ON public.ntable_2022_09_08_19 USING btree ("time");


--
-- Name: nindex_2022_09_08_20; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_20 ON public.ntable_2022_09_08_20 USING btree ("time");


--
-- Name: nindex_2022_09_08_21; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_21 ON public.ntable_2022_09_08_21 USING btree ("time");


--
-- Name: nindex_2022_09_08_22; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_22 ON public.ntable_2022_09_08_22 USING btree ("time");


--
-- Name: nindex_2022_09_08_23; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_08_23 ON public.ntable_2022_09_08_23 USING btree ("time");


--
-- Name: nindex_2022_09_09_00; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_00 ON public.ntable_2022_09_09_00 USING btree ("time");


--
-- Name: nindex_2022_09_09_01; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_01 ON public.ntable_2022_09_09_01 USING btree ("time");


--
-- Name: nindex_2022_09_09_02; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_02 ON public.ntable_2022_09_09_02 USING btree ("time");


--
-- Name: nindex_2022_09_09_03; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_03 ON public.ntable_2022_09_09_03 USING btree ("time");


--
-- Name: nindex_2022_09_09_04; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_04 ON public.ntable_2022_09_09_04 USING btree ("time");


--
-- Name: nindex_2022_09_09_05; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_05 ON public.ntable_2022_09_09_05 USING btree ("time");


--
-- Name: nindex_2022_09_09_06; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_06 ON public.ntable_2022_09_09_06 USING btree ("time");


--
-- Name: nindex_2022_09_09_07; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_07 ON public.ntable_2022_09_09_07 USING btree ("time");


--
-- Name: nindex_2022_09_09_08; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_08 ON public.ntable_2022_09_09_08 USING btree ("time");


--
-- Name: nindex_2022_09_09_09; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_09 ON public.ntable_2022_09_09_09 USING btree ("time");


--
-- Name: nindex_2022_09_09_10; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_10 ON public.ntable_2022_09_09_10 USING btree ("time");


--
-- Name: nindex_2022_09_09_11; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_11 ON public.ntable_2022_09_09_11 USING btree ("time");


--
-- Name: nindex_2022_09_09_12; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_12 ON public.ntable_2022_09_09_12 USING btree ("time");


--
-- Name: nindex_2022_09_09_13; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_13 ON public.ntable_2022_09_09_13 USING btree ("time");


--
-- Name: nindex_2022_09_09_14; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_14 ON public.ntable_2022_09_09_14 USING btree ("time");


--
-- Name: nindex_2022_09_09_15; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_15 ON public.ntable_2022_09_09_15 USING btree ("time");


--
-- Name: nindex_2022_09_09_16; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_16 ON public.ntable_2022_09_09_16 USING btree ("time");


--
-- Name: nindex_2022_09_09_17; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_17 ON public.ntable_2022_09_09_17 USING btree ("time");


--
-- Name: nindex_2022_09_09_18; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_18 ON public.ntable_2022_09_09_18 USING btree ("time");


--
-- Name: nindex_2022_09_09_19; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_19 ON public.ntable_2022_09_09_19 USING btree ("time");


--
-- Name: nindex_2022_09_09_20; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_20 ON public.ntable_2022_09_09_20 USING btree ("time");


--
-- Name: nindex_2022_09_09_21; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_21 ON public.ntable_2022_09_09_21 USING btree ("time");


--
-- Name: nindex_2022_09_09_22; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_22 ON public.ntable_2022_09_09_22 USING btree ("time");


--
-- Name: nindex_2022_09_09_23; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_09_23 ON public.ntable_2022_09_09_23 USING btree ("time");


--
-- Name: nindex_2022_09_10_00; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_00 ON public.ntable_2022_09_10_00 USING btree ("time");


--
-- Name: nindex_2022_09_10_01; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_01 ON public.ntable_2022_09_10_01 USING btree ("time");


--
-- Name: nindex_2022_09_10_02; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_02 ON public.ntable_2022_09_10_02 USING btree ("time");


--
-- Name: nindex_2022_09_10_03; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_03 ON public.ntable_2022_09_10_03 USING btree ("time");


--
-- Name: nindex_2022_09_10_04; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_04 ON public.ntable_2022_09_10_04 USING btree ("time");


--
-- Name: nindex_2022_09_10_05; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_05 ON public.ntable_2022_09_10_05 USING btree ("time");


--
-- Name: nindex_2022_09_10_06; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_06 ON public.ntable_2022_09_10_06 USING btree ("time");


--
-- Name: nindex_2022_09_10_07; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_07 ON public.ntable_2022_09_10_07 USING btree ("time");


--
-- Name: nindex_2022_09_10_08; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_08 ON public.ntable_2022_09_10_08 USING btree ("time");


--
-- Name: nindex_2022_09_10_09; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_09 ON public.ntable_2022_09_10_09 USING btree ("time");


--
-- Name: nindex_2022_09_10_10; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_10 ON public.ntable_2022_09_10_10 USING btree ("time");


--
-- Name: nindex_2022_09_10_11; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_11 ON public.ntable_2022_09_10_11 USING btree ("time");


--
-- Name: nindex_2022_09_10_12; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_12 ON public.ntable_2022_09_10_12 USING btree ("time");


--
-- Name: nindex_2022_09_10_13; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_13 ON public.ntable_2022_09_10_13 USING btree ("time");


--
-- Name: nindex_2022_09_10_14; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_14 ON public.ntable_2022_09_10_14 USING btree ("time");


--
-- Name: nindex_2022_09_10_15; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_15 ON public.ntable_2022_09_10_15 USING btree ("time");


--
-- Name: nindex_2022_09_10_16; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_16 ON public.ntable_2022_09_10_16 USING btree ("time");


--
-- Name: nindex_2022_09_10_17; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_17 ON public.ntable_2022_09_10_17 USING btree ("time");


--
-- Name: nindex_2022_09_10_18; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_18 ON public.ntable_2022_09_10_18 USING btree ("time");


--
-- Name: nindex_2022_09_10_19; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_19 ON public.ntable_2022_09_10_19 USING btree ("time");


--
-- Name: nindex_2022_09_10_20; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_20 ON public.ntable_2022_09_10_20 USING btree ("time");


--
-- Name: nindex_2022_09_10_21; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_21 ON public.ntable_2022_09_10_21 USING btree ("time");


--
-- Name: nindex_2022_09_10_22; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_22 ON public.ntable_2022_09_10_22 USING btree ("time");


--
-- Name: nindex_2022_09_10_23; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_10_23 ON public.ntable_2022_09_10_23 USING btree ("time");


--
-- Name: nindex_2022_09_11_00; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_00 ON public.ntable_2022_09_11_00 USING btree ("time");


--
-- Name: nindex_2022_09_11_01; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_01 ON public.ntable_2022_09_11_01 USING btree ("time");


--
-- Name: nindex_2022_09_11_02; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_02 ON public.ntable_2022_09_11_02 USING btree ("time");


--
-- Name: nindex_2022_09_11_03; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_03 ON public.ntable_2022_09_11_03 USING btree ("time");


--
-- Name: nindex_2022_09_11_04; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_04 ON public.ntable_2022_09_11_04 USING btree ("time");


--
-- Name: nindex_2022_09_11_05; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_05 ON public.ntable_2022_09_11_05 USING btree ("time");


--
-- Name: nindex_2022_09_11_06; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_06 ON public.ntable_2022_09_11_06 USING btree ("time");


--
-- Name: nindex_2022_09_11_07; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_07 ON public.ntable_2022_09_11_07 USING btree ("time");


--
-- Name: nindex_2022_09_11_08; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_08 ON public.ntable_2022_09_11_08 USING btree ("time");


--
-- Name: nindex_2022_09_11_09; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_09 ON public.ntable_2022_09_11_09 USING btree ("time");


--
-- Name: nindex_2022_09_11_10; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_10 ON public.ntable_2022_09_11_10 USING btree ("time");


--
-- Name: nindex_2022_09_11_11; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_11 ON public.ntable_2022_09_11_11 USING btree ("time");


--
-- Name: nindex_2022_09_11_12; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_12 ON public.ntable_2022_09_11_12 USING btree ("time");


--
-- Name: nindex_2022_09_11_13; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_13 ON public.ntable_2022_09_11_13 USING btree ("time");


--
-- Name: nindex_2022_09_11_14; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_14 ON public.ntable_2022_09_11_14 USING btree ("time");


--
-- Name: nindex_2022_09_11_15; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_15 ON public.ntable_2022_09_11_15 USING btree ("time");


--
-- Name: nindex_2022_09_11_16; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_16 ON public.ntable_2022_09_11_16 USING btree ("time");


--
-- Name: nindex_2022_09_11_17; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_17 ON public.ntable_2022_09_11_17 USING btree ("time");


--
-- Name: nindex_2022_09_11_18; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_18 ON public.ntable_2022_09_11_18 USING btree ("time");


--
-- Name: nindex_2022_09_11_19; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_19 ON public.ntable_2022_09_11_19 USING btree ("time");


--
-- Name: nindex_2022_09_11_20; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_20 ON public.ntable_2022_09_11_20 USING btree ("time");


--
-- Name: nindex_2022_09_11_21; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_21 ON public.ntable_2022_09_11_21 USING btree ("time");


--
-- Name: nindex_2022_09_11_22; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_22 ON public.ntable_2022_09_11_22 USING btree ("time");


--
-- Name: nindex_2022_09_11_23; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_11_23 ON public.ntable_2022_09_11_23 USING btree ("time");


--
-- Name: nindex_2022_09_12_00; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_12_00 ON public.ntable_2022_09_12_00 USING btree ("time");


--
-- Name: nindex_2022_09_12_01; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_12_01 ON public.ntable_2022_09_12_01 USING btree ("time");


--
-- Name: nindex_2022_09_12_02; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_12_02 ON public.ntable_2022_09_12_02 USING btree ("time");


--
-- Name: nindex_2022_09_12_03; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_12_03 ON public.ntable_2022_09_12_03 USING btree ("time");


--
-- Name: nindex_2022_09_12_11; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX nindex_2022_09_12_11 ON public.ntable_2022_09_12_11 USING btree ("time");


--
-- Name: partition_table aaa; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER aaa BEFORE INSERT ON public.partition_table FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();


--
-- Name: partition_table1 aaa1; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER aaa1 BEFORE INSERT ON public.partition_table1 FOR EACH ROW EXECUTE FUNCTION public.update_timestamp1();


--
-- Name: partition_table2 aaa2; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER aaa2 BEFORE INSERT ON public.partition_table2 FOR EACH ROW EXECUTE FUNCTION public.update_timestamp2();


--
-- PostgreSQL database dump complete
--

