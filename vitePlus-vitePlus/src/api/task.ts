import { springGet, springPost, springPut, springDelete } from "@/api/http";
import type {
  HistoryId,
  ID,
  OnlineServiceDetailDTO,
  OnlineServiceExtraConfDTO,
  OnlineServiceItem,
  OnlineServiceLogDTO,
  OnlineServiceVisualizationHistogramDTO,
  OnlineServiceVisualizationLineDTO,
  OnlineServiceVisualizationPieDTO,
  Result,
  TaskConfigurationDTO,
  TaskHistoryItem,
  TaskId,
  TaskListItem,
  TrainResultData,
} from "@/api/types";

// TaskManageController
export const taskManage = {
  addTask: (task: unknown) => springPost<unknown>("/task/TaskManage/AddTask", task),
  judgeTaskNameRepeat: (params: { name: string; task_id?: string }) =>
    springGet<unknown>("/task/TaskManage/JudgeTaskNameRepeat", { params }),
  getTaskList: (): Promise<Result<TaskListItem[]>> => springGet<TaskListItem[]>("/task/TaskManage/GetTaskList"),
  getSingleTaskDetail: (params: { task_id: string }) =>
    springGet<TaskHistoryItem[]>("/task/TaskManage/GetSingleTaskDetail", { params }),
  getTaskConfigurationById: (params: { task_id: string }) =>
    springGet<TaskConfigurationDTO>("/task/TaskManage/GetTaskConfigurationById", { params }),
  deleteTask: (params: { task_id: string }) =>
    springDelete<unknown>("/task/TaskManage/DeleteTask", { params }),
  updateTask: (task: unknown) => springPut<unknown>("/task/TaskManage/UpdateTask", task),
  getTrainResultData: (params: { task_id: string; history_id: string }) =>
    springGet<TrainResultData>("/task/TaskManage/GetTrainResultData", { params }),
};

// OnlineServiceController
export const onlineService = {
  getOnlineServiceList: (params?: Partial<OnlineServiceItem>) =>
    springGet<OnlineServiceItem[]>("/task/OnlineService/GetOnlineServiceList", { params: params || {} }),
  getOnlineService: (params: { service_id: ID }) =>
    springGet<OnlineServiceDetailDTO>("/task/OnlineService/GetOnlineService", { params }),
  getExtraConf: (params: { service_id: ID }) =>
    springGet<OnlineServiceExtraConfDTO>("/task/OnlineService/GetExtraConf", { params }),
  getOnlineServiceLog: (params: { service_id: ID } & Record<string, unknown>) =>
    springGet<OnlineServiceLogDTO>("/task/OnlineService/GetOnlineServiceLog", { params }),
  getLineChart: (
    params: { service_id: ID | ID[]; time_unit?: string; start_time?: string; end_time?: string } & Record<string, unknown>
  ) =>
    springGet<OnlineServiceVisualizationLineDTO>("/task/OnlineService/OnlineServiceLogVisualization/LineChart", { params }),
  getHistogram: (
    params: { service_id: ID | ID[]; time_span_num?: number; start_time?: string; end_time?: string } & Record<string, unknown>
  ) =>
    springGet<OnlineServiceVisualizationHistogramDTO>("/task/OnlineService/OnlineServiceLogVisualization/Histogram", { params }),
  getPieChart: (params: { service_id: ID | ID[]; start_time?: string; end_time?: string } & Record<string, unknown>) =>
    springGet<OnlineServiceVisualizationPieDTO>("/task/OnlineService/OnlineServiceLogVisualization/PieChart", { params }),
};

