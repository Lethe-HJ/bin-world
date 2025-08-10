import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'image-picker',
      component: () => import('../views/ImagePickerView.vue'),
    },
    {
      path: '/image-picker',
      name: 'image-picker-alias',
      redirect: '/'
    },
  ],
})

export default router