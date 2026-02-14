import { springGet, springPost, springPut, springDelete } from "@/api/http";
import type {
  ColDataDetailDTO,
  DataDetailColumnDTO,
  DataGraphDTO,
  DataGraphResultDTO,
  DataSetInfo,
  FileDataPreview,
  FileTagListData,
  ID,
  JsonFileListData,
  JsonTagEntity,
  JsonTagStat,
  MultiDataGraphDTO,
  ScatterChartDTO,
  Result,
  TableDataDetailDTO,
} from "@/api/types";

// DataSetController / DataTableController（注意：当前后端路径存在 /data/data 前缀）
export const dataset = {
  index: (): Promise<Result<unknown>> => springGet("/data/data/index"),
  search: (params: { Search: string }): Promise<Result<DataSetInfo[]>> => springGet("/data/data/search", { params }),
  getPublic: (): Promise<Result<DataSetInfo[]>> => springGet("/data/data/GetPublicData"),
  searchPublic: (params: { Search: string }): Promise<Result<DataSetInfo[]>> => springGet("/data/data/SearchPublicData", { params }),
  getAll: (): Promise<Result<DataSetInfo[]>> => springGet("/data/data/GetAllData"),
  searchAll: (params: { Search: string }): Promise<Result<DataSetInfo[]>> => springGet("/data/data/SearchAllData", { params }),
  getAllDataSetDataTableDataColumns: (): Promise<Result<DataSetInfo[]>> => springGet("/data/data/GetAllDataSetDataTableDataColumns"),
  create: (data: Partial<DataSetInfo>) => springPost<unknown>("/data/data/dataset", data),
  update: (data: Partial<DataSetInfo>) => springPut<unknown>("/data/data/dataset", data),
  remove: (set_id: number) => springDelete<unknown>(`/data/data/dataset/${set_id}`),
  updateTable: (data: unknown) => springPut<unknown>("/data/data/datatable", data),
  removeTable: (table_id: number) => springDelete<unknown>(`/data/data/datatable/${table_id}`),
};

export const sqlUpload = {
  // DataScreen 里按 columnsName/columnsNum/columnsData 解析
  getUserSqlTable: (params: Record<string, unknown>) => springGet<FileDataPreview>("/data/SqlUpload/GetUserSqlTable", { params }),
  saveUserSqlTable: (params: Record<string, unknown>) => springPost<unknown>("/data/SqlUpload/SaveUserSqlTable", params, {
    headers: { "Content-Type": "multipart/form-data" },
  }),
};

export const file = {
  getTagList: (form: Record<string, unknown>) =>
    springPost<FileTagListData>("/data/File/getTagList", form, { headers: { "Content-Type": "multipart/form-data" } }),
  getFileData: (form: Record<string, unknown>) =>
    springPost<FileDataPreview>("/data/File/GetFileData", form, { headers: { "Content-Type": "multipart/form-data" } }),
  saveJson: (form: Record<string, unknown>) =>
    springPost<unknown>("/data/File/saveJson", form, { headers: { "Content-Type": "multipart/form-data" } }),
  upload: (form: Record<string, unknown>) =>
    springPost<unknown>("/data/File/Upload", form, { headers: { "Content-Type": "multipart/form-data" } }),
};

export const dataVisualization = {
  dataGraph: (params: Record<string, unknown>) => springGet<DataGraphResultDTO>("/data/DataVisualization/DataGraph", { params }),
  scatterChart: (params: Record<string, unknown>) => springGet<ScatterChartDTO>("/data/DataVisualization/ScatterChart", { params }),
  multiDataGraph: (params: Record<string, unknown>) => springGet<MultiDataGraphDTO>("/data/DataVisualization/MultiDataGraph", { params }),
};

export const dataDetail = {
  datadetail: (params: { table_id: ID }) => springGet<DataDetailColumnDTO[]>("/data/datadetail", { params }),
  tableDataDetail: (table_id: ID, pageNum: number, pageSize: number) =>
    springGet<TableDataDetailDTO>(`/data/dataViewDetail/tableDataDetail/${table_id}/${pageNum}/${pageSize}`),
  colDataDetail: (table_id: ID, col_name: string, pageNum: number) =>
    springGet<ColDataDetailDTO>(`/data/dataViewDetail/colDataDetail/${table_id}/${col_name}/${pageNum}`),
  colData: (params: Record<string, unknown>) => springGet<unknown>("/data/dataViewDetail/colData", { params }),
};

export const jsonDetail = {
  getTagList: (params: { datasetId: string; tableId: string }) =>
    springGet<JsonTagStat[]>("/data/jsonDetail/getTagList", { params }),
  getTagDedupeList: (params: { datasetId: string; tableId: string }) =>
    springGet<JsonTagStat[]>("/data/jsonDetail/getTagDedupeList", { params }),
  getTagEntityList: (params: { datasetId: string; tableId: string; tagName: string }) =>
    springGet<JsonTagEntity[]>("/data/jsonDetail/getTagEntityList", { params }),
  getFileList: (params: { datasetId: string; tableId: string; currentPage: number; pageSize: number }) =>
    springGet<JsonFileListData>("/data/jsonDetail/getFileList", { params }),
};

