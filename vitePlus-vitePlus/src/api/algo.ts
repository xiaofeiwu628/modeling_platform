import { algo } from "@/api/http";
import type {
  AlgoMergeSliceReq,
  AlgoRawResp,
  AlgoResp,
  AlgoImagePushReq,
  AlgoServiceCustomDeployReq,
  AlgoServiceDeployReq,
  AlgoTaskCreateReq,
  AlgoTaskModifyReq,
  AlgoTaskSaveReq,
  ID,
} from "@/api/types";

// FastAPI（经 Gateway /algo）
export const algoTask = {
  create: (params: AlgoTaskCreateReq, signal?: AbortSignal): AlgoResp<unknown> =>
    algo.post("/task/create", params, signal ? { signal } : undefined),
  save: (params: AlgoTaskSaveReq, signal?: AbortSignal): AlgoResp<unknown> =>
    algo.post("/task/save", params, signal ? { signal } : undefined),
  start: (params: { task_id: string }, signal?: AbortSignal): AlgoResp<unknown> =>
    algo.post("/task/start", params, signal ? { signal } : undefined),
  stop: (params: { task_id: string }, signal?: AbortSignal): AlgoResp<unknown> =>
    algo.post("/task/stop", params, signal ? { signal } : undefined),
  modify: (params: AlgoTaskModifyReq, signal?: AbortSignal): AlgoResp<unknown> =>
    algo.post("/task/modify", params, signal ? { signal } : undefined),
  delete: (params: { task_id: string }, signal?: AbortSignal): AlgoResp<unknown> =>
    algo.post("/task/delete", params, signal ? { signal } : undefined),
  // 页面直接把 res.data 当作日志文本处理（非 envelope）
  containerLog: (task_id: string): AlgoRawResp<string> => algo.get(`/task/container_log/${task_id}`),
};

export const algoService = {
  deploy: (params: AlgoServiceDeployReq): AlgoResp<unknown> => algo.post("/service/deploy", params),
  start: (params: { service_id: ID }): AlgoResp<unknown> => algo.post("/service/start", params),
  stop: (params: { service_id: ID }): AlgoResp<unknown> => algo.post("/service/stop", params),
  delete: (params: { service_id: ID }): AlgoResp<unknown> => algo.post("/service/delete", params),
  modelDelete: (params: { model_id: ID }): AlgoResp<unknown> => algo.post("/service/model_delete", params),
  customSave: (params: Record<string, unknown>): AlgoResp<unknown> => algo.post("/service/custom_save", params),
  customModify: (params: Record<string, unknown>): AlgoResp<unknown> => algo.post("/service/custom_modify", params),
  customDelete: (params: { image_id: ID } | Record<string, unknown>): AlgoResp<unknown> =>
    algo.post("/service/custom_delete", params),
  imageVersionDelete: (params: { image_version_id: ID }): AlgoResp<unknown> =>
    algo.post("/service/image_version_delete", params),
  customDeploy: (params: AlgoServiceCustomDeployReq): AlgoResp<unknown> => algo.post("/service/custom_deploy", params),
};

export const algoFile = {
  uploadSlice: (params: FormData, signal?: AbortSignal): AlgoResp<void> =>
    algo.post("/file/upload-slice", params, signal ? { signal } : undefined),
  mergeSlice: (params: AlgoMergeSliceReq, signal?: AbortSignal): AlgoResp<void> =>
    algo.put("/file/merge-slice", params, signal ? { signal } : undefined),
  // API.md: body 为 JSON string
  uploadCancel: (identifier: string): AlgoResp<void> => algo.post("/file/upload-cancel", identifier),
};

export const algoImage = {
  push: (params: AlgoImagePushReq, signal?: AbortSignal): AlgoResp<void> =>
    algo.post("/image/push", params, signal ? { signal } : undefined),
};

