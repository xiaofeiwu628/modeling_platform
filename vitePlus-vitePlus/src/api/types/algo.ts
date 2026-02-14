import type { AxiosResponse } from "axios";
import type { ID } from "./common";

/**
 * FastAPI 返回并不完全统一：
 * - 部分接口：{ code: 200, massage: {...} }（历史字段 massage）
 * - 部分接口：{ code: 200, message/msg: "..." }
 * - 也有接口直接返回纯文本/数组（如 container_log）
 */
export interface AlgoEnvelope<T = unknown> {
  code: number;
  message?: string;
  msg?: string;
  // 历史拼写：massage
  massage?: T;
  // 有些接口可能使用 data
  data?: T;
  [k: string]: unknown;
}

/** 默认按“带 envelope”的接口建模 */
export type AlgoResp<T = unknown> = Promise<AxiosResponse<AlgoEnvelope<T>>>;

/** 纯数据返回（非 envelope） */
export type AlgoRawResp<T = unknown> = Promise<AxiosResponse<T>>;

/** 常用成功分支：code === 200 时可用来做更强的类型缩窄 */
export type AlgoOkEnvelope<T = unknown> = AlgoEnvelope<T> & { code: 200 };

// --- Request DTOs (按 API.md + 页面真实用法收紧) ---
export interface AlgoMergeSliceReq {
  name: string;
  total_slice: number;
  identifier: string;
}

export interface AlgoUploadCancelReq {
  // API.md: body 为 JSON string
  // 页面里传 JSON.stringify(identifier)
  // 所以这里保持 string 即可
  identifier: string;
}

export interface AlgoImagePushReq {
  image_id: ID;
  image_name: string;
  tag: string;
  md5: string;
  file_name: string;
  desc: string;
}

export interface AlgoTaskCreateReq {
  task_desc: string;
  name: string;
  type: string;
  configuration: Record<string, unknown>;
}

export interface AlgoTaskModifyReq extends AlgoTaskCreateReq {
  task_id: string;
}

export type AlgoTaskSaveReq = AlgoTaskCreateReq;

export interface AlgoServiceDeployReq {
  model_id: ID;
  task_id: string;
  task_history_id: string;
  service_name: string;
  service_desc: string;
  memory: number;
  cpu_cores_num: number;
}

export interface AlgoServiceCustomDeployReq {
  image_version_id: ID;
  image_name: string;
  image_tag: string;
  service_name: string;
  service_desc: string;
  memory: number;
  cpu_cores_num: number;
  image_port: string;
  // 页面实际会额外带 env/type 等字段，这里留扩展位
  [k: string]: unknown;
}

// --- Response DTOs (最小但严格覆盖页面判断) ---
export interface AlgoOkMessage {
  // FastAPI 这里 code 通常是 200（页面用 === 200 判断）
  code: 200;
  message?: string;
  msg?: string;
  [k: string]: unknown;
}

