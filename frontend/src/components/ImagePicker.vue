<template>
  <div class="image-picker">
    <div class="picker-container">
      <div class="picker-area" @click="selectImage" @dragover.prevent @drop="handleDrop">
        <div v-if="!selectedImage" class="placeholder">
          <div class="upload-icon">🖼️</div>
          <h3>选择图片文件</h3>
          <p class="hint">点击此区域选择图片，或拖拽图片文件到此处</p>
          <p class="formats">支持 JPG、PNG、GIF、WebP、SVG 等格式</p>
          <button class="select-btn">浏览文件</button>
        </div>
        
        <div v-else class="image-container">
          <div class="image-wrapper">
            <img v-if="imageUrl" :src="imageUrl" :alt="selectedImage.name" class="preview-image" />
            <div v-else class="image-placeholder">
              <div class="loading">📷</div>
              <p>加载图片中...</p>
            </div>
          </div>
          <div class="image-info">
            <h3>{{ selectedImage.name }}</h3>
            <div class="file-details">
              <span v-if="selectedImage.size" class="file-size">
                {{ FileDialog.formatFileSize(selectedImage.size) }}
              </span>
              <span class="file-path" :title="selectedImage.path">
                {{ selectedImage.path }}
              </span>
            </div>
            <div class="actions">
              <button @click.stop="selectImage" class="change-btn">更换图片</button>
              <button @click.stop="clearImage" class="clear-btn">清除</button>
            </div>
          </div>
        </div>
      </div>
      
      <div v-if="error" class="error">
        <p>{{ error }}</p>
      </div>
      
      <!-- 提示信息 -->
      <div v-if="isTauriEnv" class="dev-hint">
        <p>💡 按 <kbd>Cmd+Option+I</kbd> (macOS) 或 <kbd>Ctrl+Shift+I</kbd> (Windows/Linux) 打开开发者工具</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import { FileDialog } from '@/utils/fileDialog'
import type { FileInfo } from '@/types/file'

const selectedImage = ref<FileInfo | null>(null)
const imageUrl = ref<string>('')
const error = ref<string>('')
const isTauriEnv = ref(typeof window !== 'undefined' && (window as any).__TAURI__)

const selectImage = async () => {
  error.value = ''
  
  const result = await FileDialog.openImageFile({
    title: '选择图片文件'
  })
  
  if (result.success && result.data) {
    selectedImage.value = result.data as FileInfo
    // 立即加载图片 URL
    await loadImageUrl()
  } else {
    error.value = result.error || '图片选择失败'
  }
}

const loadImageUrl = async () => {
  if (!selectedImage.value) return
  
  try {
    // 检查是否在 Tauri 环境中
    if (typeof window !== 'undefined' && (window as any).__TAURI__) {
      // 在 Tauri 环境中，使用 convertFileSrc
      const { convertFileSrc } = await import('@tauri-apps/api/core')
      imageUrl.value = convertFileSrc(selectedImage.value.path)
    } else {
      // 在普通 web 环境中，path 已经是 blob URL
      imageUrl.value = selectedImage.value.path
    }
  } catch (error) {
    console.error('加载图片失败:', error)
    error.value = '无法加载图片预览'
  }
}

const handleDrop = async (e: DragEvent) => {
  e.preventDefault()
  
  const files = e.dataTransfer?.files
  if (!files || files.length === 0) return
  
  const file = files[0]
  if (!FileDialog.isImageFile(file.name)) {
    error.value = '请选择图片文件'
    return
  }
  
  selectedImage.value = {
    name: file.name,
    path: file.name,
    size: file.size
  }
  
  // 在拖拽情况下，直接创建 blob URL
  imageUrl.value = URL.createObjectURL(file)
  error.value = ''
}

const clearImage = () => {
  selectedImage.value = null
  imageUrl.value = ''
  error.value = ''
  
  // 清理 blob URL
  if (imageUrl.value && imageUrl.value.startsWith('blob:')) {
    URL.revokeObjectURL(imageUrl.value)
  }
}

// 监听 selectedImage 变化，自动加载图片
watch(selectedImage, () => {
  if (selectedImage.value && !imageUrl.value) {
    loadImageUrl()
  }
})
</script>

<style scoped>
.image-picker {
  padding: 30px;
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
}

.picker-container {
  width: 100%;
  max-width: 900px;
}

.picker-area {
  border: 3px dashed #e0e0e0;
  border-radius: 12px;
  padding: 40px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s ease;
  background: #fafafa;
  min-height: 400px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.picker-area:hover {
  border-color: #007bff;
  background: #f8f9ff;
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(0, 123, 255, 0.1);
}

.placeholder {
  color: #666;
}

.upload-icon {
  font-size: 64px;
  margin-bottom: 20px;
  display: block;
}

.placeholder h3 {
  margin: 0 0 15px 0;
  font-size: 24px;
  font-weight: 600;
  color: #333;
}

.hint {
  font-size: 16px;
  color: #666;
  margin: 10px 0;
  line-height: 1.5;
}

.formats {
  font-size: 14px;
  color: #999;
  margin: 15px 0 25px 0;
}

.select-btn {
  background: linear-gradient(135deg, #007bff, #0056b3);
  color: white;
  border: none;
  padding: 12px 30px;
  border-radius: 25px;
  font-size: 16px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 4px 15px rgba(0, 123, 255, 0.3);
}

.select-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(0, 123, 255, 0.4);
}

.image-container {
  width: 100%;
  display: grid;
  grid-template-columns: 1fr 300px;
  gap: 30px;
  align-items: start;
}

.image-wrapper {
  background: white;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
}

.preview-image {
  max-width: 100%;
  max-height: 400px;
  width: auto;
  height: auto;
  object-fit: contain;
  border-radius: 8px;
  display: block;
  margin: 0 auto;
}

.image-placeholder {
  text-align: center;
  padding: 60px 20px;
  color: #666;
}

.loading {
  font-size: 48px;
  margin-bottom: 15px;
}

.image-info {
  background: white;
  padding: 25px;
  border-radius: 8px;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
  text-align: left;
}

.image-info h3 {
  margin: 0 0 15px 0;
  color: #333;
  font-size: 18px;
  font-weight: 600;
  word-break: break-word;
}

.file-details {
  margin-bottom: 20px;
}

.file-size {
  display: inline-block;
  background: #e7f3ff;
  color: #0066cc;
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 14px;
  font-weight: 500;
  margin-bottom: 10px;
}

.file-path {
  display: block;
  font-size: 13px;
  color: #666;
  word-break: break-all;
  line-height: 1.4;
  margin-top: 8px;
}

.actions {
  display: flex;
  gap: 10px;
}

.change-btn {
  background: #28a745;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.3s ease;
}

.change-btn:hover {
  background: #218838;
  transform: translateY(-1px);
}

.clear-btn {
  background: #dc3545;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.3s ease;
}

.clear-btn:hover {
  background: #c82333;
  transform: translateY(-1px);
}

.error {
  background: #f8d7da;
  color: #721c24;
  padding: 15px;
  border-radius: 8px;
  border: 1px solid #f5c6cb;
  margin-top: 20px;
  text-align: center;
  font-weight: 500;
}

.dev-hint {
  margin-top: 25px;
  text-align: center;
  background: #e7f3ff;
  padding: 15px;
  border-radius: 8px;
  border: 1px solid #bee5eb;
}

.dev-hint p {
  margin: 0;
  font-size: 14px;
  color: #0c5460;
}

.dev-hint kbd {
  background: #f8f9fa;
  border: 1px solid #dee2e6;
  border-radius: 4px;
  padding: 3px 6px;
  font-size: 13px;
  color: #495057;
  font-weight: 600;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .image-container {
    grid-template-columns: 1fr;
    gap: 20px;
  }
  
  .picker-area {
    padding: 30px 20px;
    min-height: 300px;
  }
  
  .upload-icon {
    font-size: 48px;
  }
  
  .placeholder h3 {
    font-size: 20px;
  }
}
</style>