import type { ID } from "./common";
import type { HistoryId, TaskId } from "./task";

export interface ModelItem {
  model_id: ID;
  model_name: string;
  model_desc?: string;
  task_id: TaskId;
  task_history_id?: HistoryId;
  task_type?: string;
  model_state?: string;
  is_public: string | number;
  deploy_permission?: number;
  [k: string]: unknown;
}

export interface GetVersionDTO {
  task_history_id: HistoryId[];
  model_version?: string;
  [k: string]: unknown;
}

export interface ImageVersionItem {
  image_version_id: ID;
  tag: string;
  is_used?: number;
  version_desc?: string;
  [k: string]: unknown;
}

export interface ImageItem {
  image_id: ID;
  image_name: string;
  image_desc?: string;
  is_public: number;
  version_num?: number | string;
  image_version?: ImageVersionItem[];
  [k: string]: unknown;
}

export interface ImageServiceItem {
  service_id: ID;
  service_name: string;
  service_state: string;
  [k: string]: unknown;
}

/** 该接口历史返回 data 内还可能包一层 code（前端现有逻辑使用 res.data.code） */
export interface JudgeImageVersionRepeatData {
  code: string; // "1" 表示重复（按现有前端逻辑）
  [k: string]: unknown;
}

