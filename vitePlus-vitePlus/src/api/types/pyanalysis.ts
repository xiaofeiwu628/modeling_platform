import type { AxiosResponse } from "axios";

/** python-data-service 返回结构不完全统一，这里按前端现有访问路径建模 */
export interface PyBase<T> {
  code: string;
  msg?: string;
  data: T;
  data_len?: number;
  [k: string]: unknown;
}

export interface PyAnalysisData {
  data: {
    data: Record<string, unknown>;
  };
}

export interface PyOutliersData {
  avg: number;
  stdev: number;
  xAxis: number[] | string[];
  distributeBardata: number[];
  linedata: number[];
  [k: string]: unknown;
}

export interface PyZscoreOutlierRow {
  // DataView.vue 会给每行动态加 index
  index?: number;
  [k: string]: unknown;
}

export type PyAnalysisResp = Promise<AxiosResponse<PyBase<PyAnalysisData>>>;
export type PyOutliersResp = Promise<AxiosResponse<PyBase<PyOutliersData>>>;
export type PyZscoreResp = Promise<AxiosResponse<PyBase<PyZscoreOutlierRow[]>>>;

