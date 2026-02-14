export type ID = string | number;

/** SpringBoot 微服务统一返回结构（见 API.md 3.1） */
export interface Result<T> {
  code: string; // "0" 表示成功；也可能出现 "401"/"403"/"500" 等
  msg: string;
  data: T;
}

export type ResultList<T> = Result<T[]>;

