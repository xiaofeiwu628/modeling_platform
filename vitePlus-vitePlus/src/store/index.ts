import { defineStore } from 'pinia'
import type { ModelItem } from '@/api/types'

export const useMainStore = defineStore('main', {
  state: () => ({
    myModelList: [] as ModelItem[],
    token: '',
  }),
  actions: {
    changeMyModelList(list: ModelItem[]) {
      this.myModelList = list
    },
    changeToken(token: string) {
      this.token = token
    }
  },
  getters: {
    getMyModelList: (state): ModelItem[] => state.myModelList,
    getToken: (state) => state.token,
  }
})