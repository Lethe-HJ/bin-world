import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/image-viewer',
      name: 'image-viewer',
      component: () => import('../views/ImageViewerView.vue')
    }
  ]
})

export default router