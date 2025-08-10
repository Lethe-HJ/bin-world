<template>
  <div class="viewer-page">
    <LargeImageViewer
      :image-path="imagePath"
      :show-debug="true"
      class="viewer"
    />
  </div>
</template>

<script setup lang="ts">
import LargeImageViewer from '@/components/LargeImageViewer.vue'

// 这里使用示例图片路径
const imagePath = '/resource/tissue_hires_image.png'
</script>

<style scoped>
.viewer-page {
  width: 100vw;
  height: 100vh;
  display: flex;
  flex-direction: column;
}

.viewer {
  flex: 1;
  min-height: 0;
}
</style>
