<template>
  <div class="image-picker-view">
    <header class="app-header">
      <h1>📷 Bin World</h1>
      <p>图片文件选择器</p>
    </header>
    <ImagePicker />
  </div>
</template>

<script setup lang="ts">
import ImagePicker from '@/components/ImagePicker.vue'
</script>

<style scoped>
.image-picker-view {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.app-header {
  text-align: center;
  padding: 30px 20px 0;
  background: transparent;
}

.app-header h1 {
  color: white;
  font-size: 3rem;
  font-weight: 300;
  text-shadow: 0 2px 10px rgba(0, 0, 0, 0.3);
  margin: 0;
  letter-spacing: -1px;
}

.app-header p {
  color: rgba(255, 255, 255, 0.9);
  font-size: 1.1rem;
  margin: 10px 0 0 0;
  font-weight: 300;
  text-shadow: 0 1px 3px rgba(0, 0, 0, 0.3);
}

@media (max-width: 768px) {
  .app-header h1 {
    font-size: 2.5rem;
  }
  
  .app-header p {
    font-size: 1rem;
  }
}
</style>