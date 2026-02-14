\connect graph_db

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

-- PostgreSQL Initialization Script for Graph Service
-- Converted from MySQL init.sql
-- Uses quoted identifiers to match camelCase @TableField annotations in Java entities.

--
-- Name: graph; Type: TABLE
--
CREATE TABLE IF NOT EXISTS public.graph (
    "id" BIGSERIAL PRIMARY KEY,
    "name" VARCHAR(256) NOT NULL,
    "description" VARCHAR(1024),
    "userId" BIGINT NOT NULL,
    "isPublic" SMALLINT DEFAULT 0 NOT NULL,
    "isPublish" SMALLINT DEFAULT 0 NOT NULL,
    "status" SMALLINT DEFAULT 1 NOT NULL,
    "createTime" TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updateTime" TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "isDelete" SMALLINT DEFAULT 0 NOT NULL
);
ALTER TABLE public.graph OWNER TO postgres;

COMMENT ON TABLE public.graph IS '图谱表';
COMMENT ON COLUMN public.graph."id" IS 'id';
COMMENT ON COLUMN public.graph."name" IS '图谱名称';
COMMENT ON COLUMN public.graph."description" IS '图谱描述';
COMMENT ON COLUMN public.graph."userId" IS '用户id';
COMMENT ON COLUMN public.graph."isPublic" IS '是否公开 0-私有 1-公开';
COMMENT ON COLUMN public.graph."isPublish" IS '是否发布 0-未发布 1-发布';
COMMENT ON COLUMN public.graph."status" IS '状态 0-创建成功 1-正在创建 2-创建失败';
COMMENT ON COLUMN public.graph."createTime" IS '创建时间';
COMMENT ON COLUMN public.graph."updateTime" IS '更新时间';
COMMENT ON COLUMN public.graph."isDelete" IS '是否删除';

CREATE INDEX IF NOT EXISTS "idx_graph_userId" ON public.graph ("userId");


--
-- Name: node; Type: TABLE
--
CREATE TABLE IF NOT EXISTS public.node (
    "id" BIGSERIAL PRIMARY KEY,
    "nodeId" VARCHAR(512) NOT NULL,
    "label" VARCHAR(512) NOT NULL,
    "text" VARCHAR(512) NOT NULL,
    "graphId" BIGINT NOT NULL,
    "createTime" TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updateTime" TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "isDelete" SMALLINT DEFAULT 0 NOT NULL
);
ALTER TABLE public.node OWNER TO postgres;

COMMENT ON TABLE public.node IS '节点表';
COMMENT ON COLUMN public.node."id" IS 'id';
COMMENT ON COLUMN public.node."nodeId" IS '用户定义节点id';
COMMENT ON COLUMN public.node."label" IS '节点标签';
COMMENT ON COLUMN public.node."text" IS '节点文本';
COMMENT ON COLUMN public.node."graphId" IS '图谱id';
COMMENT ON COLUMN public.node."createTime" IS '创建时间';
COMMENT ON COLUMN public.node."updateTime" IS '更新时间';
COMMENT ON COLUMN public.node."isDelete" IS '是否删除';

CREATE INDEX IF NOT EXISTS "idx_node_graphId" ON public.node ("graphId");
CREATE INDEX IF NOT EXISTS "idx_node_graphId_nodeId" ON public.node ("graphId", "nodeId");


--
-- Name: relation; Type: TABLE
--
CREATE TABLE IF NOT EXISTS public.relation (
    "id" BIGSERIAL PRIMARY KEY,
    "startNodeId" VARCHAR(512) NOT NULL,
    "relationText" VARCHAR(512),
    "endNodeId" VARCHAR(512) NOT NULL,
    "graphId" BIGINT NOT NULL,
    "createTime" TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updateTime" TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "isDelete" SMALLINT DEFAULT 0 NOT NULL
);
ALTER TABLE public.relation OWNER TO postgres;

COMMENT ON TABLE public.relation IS '关系表';
COMMENT ON COLUMN public.relation."id" IS 'id';
COMMENT ON COLUMN public.relation."startNodeId" IS '前键用户定义id';
COMMENT ON COLUMN public.relation."relationText" IS '关系';
COMMENT ON COLUMN public.relation."endNodeId" IS '后键用户定义id';
COMMENT ON COLUMN public.relation."graphId" IS '图谱id';
COMMENT ON COLUMN public.relation."createTime" IS '创建时间';
COMMENT ON COLUMN public.relation."updateTime" IS '更新时间';
COMMENT ON COLUMN public.relation."isDelete" IS '是否删除';

CREATE INDEX IF NOT EXISTS "idx_relation_graphId" ON public.relation ("graphId");


-- Seed Data: 示例图谱（userId 需在 auth_db.users 中存在）
INSERT INTO public.graph ("name", "description", "userId", "isPublic", "isPublish", "status", "isDelete")
VALUES ('示例图谱', '用于演示的示例图谱，包含人物与地点节点', 435191816, 1, 1, 0, 0);

-- 节点：人物与地点（graphId=1 对应上面插入的图谱）
INSERT INTO public.node ("nodeId", "label", "text", "graphId", "isDelete")
VALUES
    ('n1', '人物', '张三', 1, 0),
    ('n2', '人物', '李四', 1, 0),
    ('n3', '地点', '北京', 1, 0),
    ('n4', '地点', '上海', 1, 0),
    ('n5', '人物', '王五', 1, 0);

-- 关系：startNodeId/endNodeId 对应 node.nodeId
INSERT INTO public.relation ("startNodeId", "relationText", "endNodeId", "graphId", "isDelete")
VALUES
    ('n1', '认识', 'n2', 1, 0),
    ('n1', '居住', 'n3', 1, 0),
    ('n2', '前往', 'n4', 1, 0),
    ('n2', '认识', 'n5', 1, 0),
    ('n5', '居住', 'n4', 1, 0);
