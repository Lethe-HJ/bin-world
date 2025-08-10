<template>
  <div class="image-viewer" ref="container">
    <canvas ref="canvas" @wheel="handleWheel" @mousedown="handleMouseDown" @mousemove="handleMouseMove" @mouseup="handleMouseUp"></canvas>
    <div v-if="loading" class="loading">加载中...</div>
    <div class="debug-info" v-if="showDebug">
      <div>缩放: {{ zoom.toFixed(2) }}</div>
      <div>LOD: {{ currentLOD }}</div>
      <div>可见块: {{ visibleChunks.length }}</div>
      <div>已加载: {{ loadedChunks }}</div>
      <div>FPS: {{ fps }}</div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { ImageRenderer } from '../utils/imageRenderer'
import type { ImageMetadata } from '../types/image'

const props = defineProps<{
  imagePath: string
  showDebug?: boolean
}>()

const container = ref<HTMLDivElement>()
const canvas = ref<HTMLCanvasElement>()
const loading = ref(true)
const zoom = ref(1.0)
const currentLOD = ref(0)
const visibleChunks = ref<Array<{level: number, x: number, y: number}>>([])
const loadedChunks = ref(0)
const fps = ref(0)

let renderer: ImageRenderer | null = null
let isDragging = false
let lastX = 0
let lastY = 0
let animationFrame: number | null = null

// 初始化渲染器
async function initializeRenderer() {
  if (!canvas.value) return
  
  try {
    // 处理图像
    const response = await fetch('/api/process-image', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ file_path: props.imagePath })
    })
    
    if (!response.ok) {
      throw new Error('Failed to process image')
    }
    
    const metadata: ImageMetadata = await response.json()
    
    // 创建渲染器
    renderer = new ImageRenderer()
    await renderer.initialize(canvas.value, metadata)
    
    // 设置事件监听
    renderer.on('statsUpdate', (stats) => {
      currentLOD.value = stats.activeLOD
      visibleChunks.value = stats.visibleChunks
      loadedChunks.value = stats.loadedChunks
      fps.value = Math.round(stats.fps)
    })
    
    // 开始渲染循环
    startRenderLoop()
    
    loading.value = false
  } catch (error) {
    console.error('Failed to initialize renderer:', error)
    loading.value = false
  }
}

// 渲染循环
function startRenderLoop() {
  if (!renderer) return
  
  function render() {
    if (renderer) {
      renderer.render()
      animationFrame = requestAnimationFrame(render)
    }
  }
  
  render()
}

// 事件处理
function handleWheel(event: WheelEvent) {
  event.preventDefault()
  if (!renderer) return
  
  const zoomFactor = event.deltaY > 0 ? 0.9 : 1.1
  const rect = canvas.value!.getBoundingClientRect()
  const mouseX = event.clientX - rect.left
  const mouseY = event.clientY - rect.top
  
  zoom.value = renderer.zoomToPoint(mouseX, mouseY, zoom.value * zoomFactor)
}

function handleMouseDown(event: MouseEvent) {
  isDragging = true
  lastX = event.clientX
  lastY = event.clientY
}

function handleMouseMove(event: MouseEvent) {
  if (!isDragging || !renderer) return
  
  const deltaX = event.clientX - lastX
  const deltaY = event.clientY - lastY
  lastX = event.clientX
  lastY = event.clientY
  
  renderer.pan(deltaX, deltaY)
}

function handleMouseUp() {
  isDragging = false
}

// 生命周期
onMounted(() => {
  initializeRenderer()
})

onUnmounted(() => {
  if (animationFrame !== null) {
    cancelAnimationFrame(animationFrame)
  }
  if (renderer) {
    renderer.dispose()
  }
})
</script>

<style scoped>
.image-viewer {
  position: relative;
  width: 100%;
  height: 100%;
  overflow: hidden;
  background: #f0f0f0;
}

canvas {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  touch-action: none;
}

.loading {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background: rgba(0, 0, 0, 0.7);
  color: white;
  padding: 1rem 2rem;
  border-radius: 4px;
  font-size: 1.2rem;
}

.debug-info {
  position: absolute;
  top: 1rem;
  right: 1rem;
  background: rgba(0, 0, 0, 0.7);
  color: white;
  padding: 0.5rem;
  border-radius: 4px;
  font-size: 0.8rem;
  font-family: monospace;
}

.debug-info > div {
  margin: 0.2rem 0;
}
</style>
