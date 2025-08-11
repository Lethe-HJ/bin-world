<template>
  <div class="container">
    <iframe ref="frontendFrame" :src="frontendUrl" @load="onIframeLoad"></iframe>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'

// 前端应用 URL
const frontendUrl = 'http://localhost:5173'

// iframe 引用
const frontendFrame = ref<HTMLIFrameElement>()

// Tauri API 状态
let tauriLoaded = false

// 检查 Tauri 是否可用
function checkTauri() {
  if (window.__TAURI__ && window.__TAURI_IPC__) {
    tauriLoaded = true
    console.log('Tauri API loaded')
  } else {
    setTimeout(checkTauri, 100)
  }
}

// iframe 加载完成后的处理
function onIframeLoad() {
  console.log('Frontend iframe loaded')
}

// 处理来自 iframe 的消息
async function handleMessage(event: MessageEvent) {
  // 确保消息来自我们的应用
  if (event.origin !== 'http://localhost:5173') return

  // 等待 Tauri 加载完成
  if (!tauriLoaded) {
    event.source?.postMessage({
      type: 'ERROR',
      error: 'Tauri API not ready',
      requestId: event.data.requestId
    }, event.origin)
    return
  }

  const { type, payload, requestId } = event.data

  try {
    let response = null

    switch (type) {
      case 'SELECT_FILE':
        // 使用动态导入
        const { dialog } = await import('@tauri-apps/api')
        response = await dialog.open(payload)
        break

      // 可以添加其他 Tauri API 调用
      default:
        throw new Error(`Unknown message type: ${type}`)
    }

    // 发送响应回 iframe
    event.source?.postMessage({
      type: `${type}_RESPONSE`,
      payload: response,
      requestId
    }, event.origin)
  } catch (err) {
    console.error('Error in shell:', err)
    // 发送错误信息回 iframe
    event.source?.postMessage({
      type: 'ERROR',
      error: err instanceof Error ? err.message : 'Unknown error',
      requestId
    }, event.origin)
  }
}

// 组件挂载时
onMounted(() => {
  // 立即开始检查 Tauri API
  checkTauri()

  // 添加消息监听器
  window.addEventListener('message', handleMessage)
})

// 组件卸载时
onUnmounted(() => {
  // 移除消息监听器
  window.removeEventListener('message', handleMessage)
})
</script>

<style lang="less" scoped>
.container {
  margin: 0;
  padding-top: 10vh;
  display: flex;
  flex-direction: column;
  justify-content: center;
  text-align: center;

  iframe {
    width: 100%;
    height: 100%;
    margin: 0;
    padding: 0;
    border: none;
    overflow: hidden;
  }
}
</style>

<style>
:root {
  font-family: Inter, Avenir, Helvetica, Arial, sans-serif;
  font-size: 16px;
  line-height: 24px;
  font-weight: 400;

  color: #0f0f0f;
  background-color: #f6f6f6;

  font-synthesis: none;
  text-rendering: optimizeLegibility;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  -webkit-text-size-adjust: 100%;
}

</style>