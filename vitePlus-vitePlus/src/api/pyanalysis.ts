import { pyanalysis } from "@/api/http";
import type { PyAnalysisResp, PyOutliersResp, PyZscoreResp } from "@/api/types";

export const analysis = {
  getAnalysisData: (payload: { table_id: number; column: string }): PyAnalysisResp =>
    pyanalysis.post("/get_analysis_data", payload),
  getOutliersData: (payload: { table_id: number; column: string }): PyOutliersResp =>
    pyanalysis.post("/get_outliers_data", payload),
  getZscoreOutliers: (payload: { table_id: number; column: string; threshold: number; page: number }): PyZscoreResp =>
    pyanalysis.post("/get_zscore_outliers", payload),
};

