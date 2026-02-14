import type { ID } from "./common";

export interface DataTableInfo {
  table_id: number;
  table_name: string;
  columns: string[];
  row_num?: number;
  [k: string]: unknown;
}

export interface DataSetInfo {
  set_id: number;
  set_name: string;
  set_desc?: string;
  is_public?: number;
  modify_permission?: number;
  table_num?: number;
  tables?: DataTableInfo[];
  [k: string]: unknown;
}

export interface DataDetailColumnDTO {
  fieldName: string;
  dataType: string;
  variableType: string;
  unique_values?: number;
  null_value?: number;
  outliers_value?: number;
  mean_values?: number;
  variance_values?: number;
  max_values?: number;
  min_values?: number;
  median_value?: number;
  [k: string]: unknown;
}

export interface TableDataDetailDTO {
  title: string[];
  data: unknown[];
  total: number;
  [k: string]: unknown;
}

export interface ColDataDetailDTO {
  fieldData: unknown[];
  total: number;
  [k: string]: unknown;
}

export interface DataGraphDTO {
  xData?: Array<string | number>;
  yData?: Array<string | number>;
  [k: string]: unknown;
}

export interface PieItem {
  name: string;
  value: string | number;
  [k: string]: unknown;
}

/**
 * DataVisualization/DataGraph 实际返回会随 GraphType 变化：
 * - LineChart: { yData: [...] }
 * - Histogram: { xData: [...], yData: [...] }
 * - PieChart:  [{name,value}, ...]
 */
export type DataGraphResultDTO =
  | ({ yData: Array<string | number> } & { xData?: never })
  | ({ xData: Array<string | number>; yData: Array<string | number> })
  | PieItem[];

export interface MultiDataGraphSeries {
  name: string;
  data: Array<string | number>;
  [k: string]: unknown;
}

export interface MultiDataGraphDTO {
  xData: Array<string | number>;
  yData: MultiDataGraphSeries[];
  [k: string]: unknown;
}

export type ScatterPoint = [number, number];

export type ScatterChartDTO = ScatterPoint[];

// ====== jsonDetail（命名实体识别相关）======

export interface JsonTagStat {
  // EntityVisualization / EntityView 实际使用字段是 tag/count
  tag: string;
  count: number;
  [k: string]: unknown;
}

export interface JsonTagEntity {
  // EntityView 的弹窗表格至少用 entity/count
  entity: string;
  count: number;
  // EntityViewDetail 里 fileList 按 id 定位 labels
  id?: string;
  [k: string]: unknown;
}

export interface JsonFileLabel {
  // labels 表格目前是动态列，至少保证是对象
  [k: string]: unknown;
}

export interface JsonFileItem {
  id: string;
  labels: JsonFileLabel[];
  [k: string]: unknown;
}

export interface JsonFileListData {
  fileList: JsonFileItem[];
  totalItems: number;
  [k: string]: unknown;
}

// ====== FileController 上传/解析 ======

export interface FileTagListData {
  tempTableName: string;
  itemCount: number;
  tagList: JsonTagStat[];
  [k: string]: unknown;
}

export interface FileDataPreview {
  columnsName: string[];
  columnsNum: number;
  columnsData: unknown[];
  [k: string]: unknown;
}

