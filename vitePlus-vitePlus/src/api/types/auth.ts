import type { ID, Result } from "./common";

export interface LoginParams {
  Username: string;
  Password: string;
}

export interface LoginData {
  Token: string;
  Username: string;
  user_id?: ID;
}

export type LoginResult = Result<LoginData>;

export interface RegisterParams {
  Username: string;
  Password: string;
}

