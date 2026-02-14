import { springPost } from "@/api/http";
import type { GraphDetailVO, GraphSearchRequest, Result } from "@/api/types";

/** 后端要求 id/pathLength/pathCount 为数字且必填。id 以字符串传递避免 JS 大整数精度丢失。 */
export const graph = {
  search: (params: GraphSearchRequest): Promise<Result<GraphDetailVO>> => {
    const idStr = params.id != null ? String(params.id) : '';
    if (!idStr || idStr === 'NaN') {
      return Promise.reject(new Error('图谱id不能为空'));
    }
    const body = {
      id: idStr,
      searchMode: Number(params.searchMode),
      keyword: params.keyword ?? '',
      startText: params.startText ?? '',
      relationText: params.relationText ?? '',
      endText: params.endText ?? '',
      matchMode: Number(params.matchMode),
      pathLength: Number(params.pathLength) || 3,
      pathCount: Number(params.pathCount) || 200,
    };
    return springPost<GraphDetailVO>("/graph/search", body);
  },
};
/**
 * 知识图谱API接口
 * 用于与图谱服务交互
 */
import { spring } from '@/api/http'
const request = spring

// ==================== 类型定义 ====================

export interface Graph {
  /** 图谱 id（后端以字符串返回，避免大整数精度丢失） */
  id: string
  name: string
  description: string
  userId?: number
  isPublic: number
  isPublish?: number
  /** 0-创建成功 1-创建中 2-创建失败 */
  status?: number
  createTime?: string
  updateTime?: string
  isDelete?: number
}

export interface Node {
  id: number
  nodeId: string
  label: string
  text: string
  graphId: number
  createTime?: string
  updateTime?: string
}

export interface Relation {
  id: number
  startNodeId: string
  relationText: string
  endNodeId: string
  graphId: number
  createTime?: string
  updateTime?: string
}

export interface GraphPageParams {
  current?: number
  pageSize?: number
  keyword?: string
  isPublic?: number
  isPublish?: number
  status?: number
}

export interface GraphPageResult {
  total: number
  records: Graph[]
  current?: number
  size?: number
}

export interface GraphCreateParams {
  name: string
  description?: string
  isPublic?: number
  isPublish?: number
}

export interface GraphUpdateParams {
  id: string
  name?: string
  description?: string
  isPublic?: number
  isPublish?: number
  status?: number
}

export interface NodeCreateParams {
  nodeId: string
  label: string
  text: string
  /** 图谱 id（字符串避免大整数精度丢失） */
  graphId: string
}

export interface RelationCreateParams {
  startNodeId: string
  relationText: string
  endNodeId: string
  /** 图谱 id（字符串避免大整数精度丢失） */
  graphId: string
}

export interface GraphSearchResult {
  graphs: Graph[]
  nodes: Node[]
  relations: Relation[]
}

// ==================== 图谱API ====================

/**
 * 获取图谱分页列表
 */
export function getGraphPage(params: GraphPageParams = {}) {
  return request.get<GraphPageResult>('/graph/page', { params })
}

/** 我的图谱分页请求参数 */
export interface GraphGetRequest {
  current?: number
  pageSize?: number
  name?: string
  isPublic?: number
  isPublish?: number
}

/** 我的图谱分页结果（与后端 Page<GraphVO> 一致） */
export interface GraphMyPageResult {
  records: Graph[]
  total: number
  size: number
  current: number
}

/**
 * 获取我的图谱分页
 */
export function getMyGraphPage(params: GraphGetRequest = {}) {
  return request.post<GraphMyPageResult>('/graph/page/my', {
    current: params.current ?? 1,
    pageSize: params.pageSize ?? 10,
    name: params.name,
    isPublic: params.isPublic,
    isPublish: params.isPublish,
  })
}

/**
 * 创建图谱（上传节点 CSV + 关系 CSV，multipart）
 * 不设置 Content-Type，由 axios 自动添加 multipart/form-data; boundary=...
 */
export function createGraphWithFiles(formData: FormData) {
  return request.post<string>('/graph/add', formData)
}

/**
 * 获取公开图谱导航数据
 */
export function getPublicGraphNav() {
  return request.get<{ total: number; graphs: Graph[] }>('/graph/public/nav')
}

/**
 * 获取图谱详情
 */
export function getGraphDetail(id: string) {
  return request.get<Graph>(`/graph/${id}`)
}

/**
 * 创建图谱
 */
export function createGraph(data: GraphCreateParams) {
  return request.post<Graph>('/graph/add', data)
}

/**
 * 更新图谱
 */
export function updateGraph(data: GraphUpdateParams) {
  return request.put<Graph>('/graph/update', data)
}

/**
 * 删除图谱（id 传字符串避免大整数精度丢失）
 */
export function deleteGraph(id: string) {
  return request.delete(`/graph/${id}`)
}

/**
 * 发布图谱（id 传字符串避免大整数精度丢失）
 */
export function publishGraph(id: string) {
  return request.post(`/graph/${id}/publish`)
}

/**
 * 取消发布图谱
 */
export function unpublishGraph(id: string) {
  return request.post(`/graph/${id}/unpublish`)
}

/**
 * 设置图谱为公开
 */
export function makeGraphPublic(id: string) {
  return request.post(`/graph/${id}/public`)
}

/**
 * 设置图谱为私有
 */
export function makeGraphPrivate(id: string) {
  return request.post(`/graph/${id}/private`)
}

/**
 * 搜索图谱
 */
export function searchGraph(keyword: string) {
  return request.get<GraphSearchResult>('/graph/search', { 
    params: { keyword } 
  })
}

// ==================== 节点API ====================

/**
 * 获取图谱的所有节点（graphId 传字符串避免大整数精度丢失）
 */
export function getNodeList(graphId: string) {
  return request.get<Node[]>(`/node/list/${graphId}`)
}

/**
 * 获取节点详情
 */
export function getNodeDetail(id: number) {
  return request.get<Node>(`/node/${id}`)
}

/**
 * 创建节点
 */
export function createNode(data: NodeCreateParams) {
  return request.post<Node>('/node/add', data)
}

/**
 * 批量创建节点
 */
export function batchCreateNodes(nodes: NodeCreateParams[]) {
  return request.post<Node[]>('/node/batch', nodes)
}

/**
 * 更新节点
 */
export function updateNode(data: Partial<Node> & { id: number }) {
  return request.put<Node>('/node/update', data)
}

/**
 * 删除节点
 */
export function deleteNode(id: number) {
  return request.delete(`/node/${id}`)
}

// ==================== 关系API ====================

/**
 * 获取图谱的所有关系（graphId 传字符串避免大整数精度丢失）
 */
export function getRelationList(graphId: string) {
  return request.get<Relation[]>(`/relation/list/${graphId}`)
}

/**
 * 获取关系详情
 */
export function getRelationDetail(id: number) {
  return request.get<Relation>(`/relation/${id}`)
}

/**
 * 创建关系
 */
export function createRelation(data: RelationCreateParams) {
  return request.post<Relation>('/relation/add', data)
}

/**
 * 批量创建关系
 */
export function batchCreateRelations(relations: RelationCreateParams[]) {
  return request.post<Relation[]>('/relation/batch', relations)
}

/**
 * 更新关系
 */
export function updateRelation(data: Partial<Relation> & { id: number }) {
  return request.put<Relation>('/relation/update', data)
}

/**
 * 删除关系
 */
export function deleteRelation(id: number) {
  return request.delete(`/relation/${id}`)
}

// ==================== 批量操作API ====================

/**
 * 批量导入图谱数据（CSV格式）（graphId 传字符串避免大整数精度丢失）
 */
export function importGraphData(graphId: string, file: File) {
  const formData = new FormData()
  formData.append('file', file)
  formData.append('graphId', graphId)
  
  return request.post('/graph/import', formData, {
    headers: {
      'Content-Type': 'multipart/form-data'
    }
  })
}

/**
 * 导出图谱数据（CSV格式）（graphId 传字符串避免大整数精度丢失）
 */
export function exportGraphData(graphId: string) {
  return request.get(`/graph/${graphId}/export`, {
    responseType: 'blob'
  })
}

/**
 * 复制图谱（graphId 传字符串避免大整数精度丢失）
 */
export function copyGraph(graphId: string, newName: string) {
  return request.post<Graph>('/graph/copy', {
    graphId,
    newName
  })
}

// ==================== 统计API ====================

/**
 * 获取图谱统计信息（graphId 传字符串避免大整数精度丢失）
 */
export function getGraphStatistics(graphId: string) {
  return request.get<{
    nodeCount: number
    relationCount: number
    labelCount: number
    createTime: string
    updateTime: string
  }>(`/graph/${graphId}/statistics`)
}

/**
 * 获取用户的图谱统计
 */
export function getUserGraphStatistics() {
  return request.get<{
    totalGraphs: number
    publicGraphs: number
    privateGraphs: number
    publishedGraphs: number
  }>('/graph/user/statistics')
}

export default {
  // 图谱
  getGraphPage,
  getPublicGraphNav,
  getGraphDetail,
  createGraph,
  updateGraph,
  deleteGraph,
  publishGraph,
  unpublishGraph,
  makeGraphPublic,
  makeGraphPrivate,
  searchGraph,
  
  // 节点
  getNodeList,
  getNodeDetail,
  createNode,
  batchCreateNodes,
  updateNode,
  deleteNode,
  
  // 关系
  getRelationList,
  getRelationDetail,
  createRelation,
  batchCreateRelations,
  updateRelation,
  deleteRelation,
  
  // 批量操作
  importGraphData,
  exportGraphData,
  copyGraph,
  
  // 统计
  getGraphStatistics,
  getUserGraphStatistics
}
