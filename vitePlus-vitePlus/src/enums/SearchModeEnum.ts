export enum SearchModeEnum {
  /**
   * 节点
   */
  NODE = 0,
  /**
   * 关系
   */
  RELATION = 1,
  /**
   * 标签
   */
  LABEL = 2,
  /**
   * 节点和关系
   */
  NODE_AND_RELATION = 3,
}

export const SearchModeMap = {
  [SearchModeEnum.NODE]: '节点',
  [SearchModeEnum.RELATION]: '关系',
  [SearchModeEnum.LABEL]: '标签',
  [SearchModeEnum.NODE_AND_RELATION]: '节点和关系',
}
