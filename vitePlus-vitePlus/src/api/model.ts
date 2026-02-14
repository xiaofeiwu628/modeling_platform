import { springGet, springPost, springPut } from "@/api/http";
import type {
  GetVersionDTO,
  ID,
  ImageItem,
  ImageServiceItem,
  JudgeImageVersionRepeatData,
  ModelItem,
  Result,
} from "@/api/types";

export const modelRepository = {
  getVersion: (params: { task_id: string }) =>
    springGet<GetVersionDTO>("/model/ModelRepository/GetVersion", { params }),
  addModel: (data: Partial<ModelItem>) => springPost<unknown>("/model/ModelRepository/AddModel", data),
  updateModel: (data: Partial<ModelItem>) => springPut<unknown>("/model/ModelRepository/UpdateModel", data),
  getModelList: (params?: Partial<ModelItem>) =>
    springGet<ModelItem[]>("/model/ModelRepository/GetModelList", { params: params || {} }),
};

export const imageRepository = {
  getImageRepositoryList: (params?: Partial<ImageItem> & { image_name?: string; is_public?: number; image_version_id?: ID }) =>
    springGet<ImageItem[]>("/model/ImageRepository/GetImageRepositoryList", { params: params || {} }),
  getImageServiceList: (params: { image_version_id: ID }) =>
    springGet<ImageServiceItem[]>("/model/ImageRepository/GetImageServiceList", { params }),
  judgeImageVersionRepeat: (params: { image_id: ID; tag: string }) =>
    springGet<JudgeImageVersionRepeatData>("/model/ImageRepository/JudgeImageVersionRepeat", { params }),
};

