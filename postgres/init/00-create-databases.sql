
CREATE DATABASE user_data;
CREATE DATABASE data_db;
CREATE DATABASE model_db;
CREATE DATABASE task_db;
CREATE DATABASE auth_db;
CREATE DATABASE graph_db;

\connect user_data
CREATE SCHEMA IF NOT EXISTS upload_data;
