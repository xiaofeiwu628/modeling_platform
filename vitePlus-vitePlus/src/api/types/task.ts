import type { ID } from "./common";

export type TaskId = string;
export type HistoryId = string;

export interface TaskListItem {
  task_id: TaskId;
  name: string;
  type: string;
  state: string;
  create_time: string;
  [k: string]: unknown;
}

export interface TaskDetailStep {
  step: string;
  state: string;
  start_time?: string | null;
  end_time?: string | null;
  time_consuming?: string | number;
  [k: string]: unknown;
}

export interface TaskHistoryItem {
  history_id: HistoryId | number;
  current_state: string;
  total_start_time?: string | null;
  total_end_time?: string | null;
  total_time_consuming: string | number;
  detail_data: TaskDetailStep[];
  [k: string]: unknown;
}

export interface TaskConfigurationDTO {
  task_id?: TaskId;
  name: string;
  type: string;
  task_desc?: string;
  configuration: {
    model_parameters: {
      type: string;
      hyperparameter: Record<string, unknown>;
      [k: string]: unknown;
    };
    select_data: {
      set_id: number;
      task_type: string;
      set_data: Array<{
        table_id: number;
        table_name?: string;
        time_column: string | null;
        target_column: string | null;
        characteristic_columns: string[];
        [k: string]: unknown;
      }>;
      [k: string]: unknown;
    };
    feature_engineering_strategy: {
      record_processing: {
        all: boolean;
        columns: Record<
          string,
          {
            range: number[]; // 页面里 JSON.stringify(columns.range) / columns.range.length
            [k: string]: unknown;
          }
        >;
      };
      column_processing: {
        default: boolean;
        default_config: Array<Record<string, unknown>>;
        single_config: Record<string, Array<Record<string, unknown>>>;
        // TaskModify 里还有 datatype map
        datatype?: Record<string, unknown>;
        [k: string]: unknown;
      };
      [k: string]: unknown;
    };
    container_conf: {
      cpus: number;
      mem_limit: number;
      [k: string]: unknown;
    };
    train_parameters: {
      cv_enabled: boolean;
      K_Fold: number;
      test_set_division_scale: number;
      val_set_division_scale: number;
      automatically_store_after_training: number;
      model_evaluate: string;
      time_span: number;
      time_unit: string;
      [k: string]: unknown;
    };
    [k: string]: unknown;
  };
  [k: string]: unknown;
}

export interface TrainResultData {
  evaluation: Record<string, number>;
  model_conf: Record<string, unknown>;
  [k: string]: unknown;
}

export interface OnlineServiceItem {
  service_id: ID;
  service_name: string;
  service_state: string;
  service_type?: "custom" | "official" | string;
  create_time?: string;
  service_desc?: string;
  kong_url?: string;
  [k: string]: unknown;
}

export interface OnlineServiceExtraConfDTO {
  service_state: string;
  extra_conf?: {
    node_id?: string;
    container_id?: string;
    [k: string]: unknown;
  };
  [k: string]: unknown;
}

export interface OnlineServiceLogDTO {
  logList: OnlineServiceAccessLogItem[];
  timeDistribution: {
    XData: Array<string | number>;
    YData: Array<string | number>;
  };
  [k: string]: unknown;
}

export interface OnlineServiceVisualizationLineDTO {
  xData: Array<string | number>;
  yData: Array<string | number>;
}

export interface OnlineServiceVisualizationHistogramDTO {
  xData: Array<string | number>;
  yData: Array<string | number>;
}

export interface OnlineServiceVisualizationPieDTO {
  pie_chart_data: OnlineServicePieChartSlice[];
  table_data: OnlineServicePieTableRow[];
}

export interface OnlineServiceAccessLogItem {
  online_service_log_id: ID;
  response_status: string;
  status_code: number | string;
  response_duration: number | string;
  request_start_time: string;
  request_end_time: string;
  [k: string]: unknown;
}

export interface OnlineServicePieChartSlice {
  name: string;
  value: number;
  [k: string]: unknown;
}

export interface OnlineServicePieTableRow {
  status_code: number | string;
  response_status: string;
  frequency: number;
  response_duration_min: number;
  response_duration_avg: number;
  response_duration_max: number;
  [k: string]: unknown;
}

export interface OnlineServiceDetailDTO extends OnlineServiceItem {
  memory?: number;
  cpu_cores_num?: number;
  request_data?: Record<string, unknown>;
  image_version_data?: {
    image_name: string;
    image_version_id: ID;
    tag?: string;
    image_id: ID;
    [k: string]: unknown;
  };
  model_data?: {
    model_name: string;
    is_public: string | number;
    [k: string]: unknown;
  };
  model_id?: ID;
  task_id?: TaskId;
  task_history_id?: HistoryId;
}

