import type { GraphMatchModeEnum } from '@/enums/GraphMatchModeEnum'
import type { SearchModeEnum } from '@/enums/SearchModeEnum'

/**
 * 节点类型
 */
export type Category = {
  /**
   * 类型
   */
  name?: string
}

/**
 * 图谱关系
 */
export type Link = {
  /**
   * 前键id
   */
  source?: string
  /**
   * 后键id
   */
  target?: string
  /**
   * 关系值
   */
  value?: string
  /**
   * 边的样式
   */
  lineStyle?: {
    curveness?: number
  }
}

/**
 * 图谱节点
 */
export type Node = {
  /**
   * 节点类型
   */
  category?: number
  /**
   * 节点id
   */
  id?: string
  /**
   * 节点名称
   */
  name?: string
}

/**
 * 图谱详情VO
 */
export type GraphDetailVO = {
  /**
   * 类型列表
   */
  categories: Array<Category>
  /**
   * 图谱id
   */
  id: string
  /**
   * 关系列表
   */
  links: Array<Link>
  /**
   * 图谱名称
   */
  name: string
  /**
   * 节点列表
   */
  nodes: Array<Node>
}

/**
 * 查看图谱请求
 */
export type GraphSearchRequest = {
  /**
   * 图谱id
   */
  id?: string
  /**
   * 查询模式
   */
  searchMode: SearchModeEnum
  /**
   * 关键字
   */
  keyword?: string
  /**
   * 后键名称
   */
  endText?: string
  /**
   * 查询模式 0-模糊 1-精确
   */
  matchMode: GraphMatchModeEnum
  /**
   * 关系名称
   */
  relationText?: string
  /**
   * 前键名称
   */
  startText?: string
  /**
   * 路径长度
   */
  pathLength?: number
  /**
   * 路径数量
   */
  pathCount?: number
}
