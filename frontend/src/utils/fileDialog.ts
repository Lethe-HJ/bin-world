import type { FileInfo, FileDialogOptions, FileDialogResult } from '@/types/file'

export class FileDialog {
  /**
   * 打开图片文件选择对话框
   */
  static async openImageFile(options?: FileDialogOptions): Promise<FileDialogResult> {
    try {
      // 图片文件过滤器
      const imageFilters = [
        {
          name: '图片文件',
          extensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg']
        }
      ]

      // 检查是否在 Tauri 环境中
      if (typeof window !== 'undefined' && (window as any).__TAURI__) {
        // 在 Tauri 环境中，使用 Tauri API
        const { invoke } = await import('@tauri-apps/api/core')
        
        // 在开发环境下，设置默认目录为 resource 目录
        const isDev = import.meta.env.DEV
        const dialogOptions: any = {
          title: options?.title || '选择图片文件',
          filters: imageFilters
        }
        
        if (isDev) {
          // 在开发环境下，设置默认目录
          dialogOptions.defaultPath = './resource'
        }
        
        const result = await invoke('open_file_dialog', dialogOptions)
        
        if (result) {
          return {
            success: true,
            data: result as FileInfo
          }
        } else {
          return {
            success: false
          }
        }
      } else {
        // 在普通 web 环境中，使用标准的文件 API
        return new Promise((resolve) => {
          const input = document.createElement('input')
          input.type = 'file'
          input.accept = 'image/*'
          
          input.onchange = (e) => {
            const file = (e.target as HTMLInputElement).files?.[0]
            if (file) {
              // 在 web 环境中，创建 blob URL 作为路径
              const blobUrl = URL.createObjectURL(file)
              const fileInfo: FileInfo = {
                name: file.name,
                path: blobUrl, // 使用 blob URL 作为路径
                size: file.size
              }
              resolve({
                success: true,
                data: fileInfo
              })
            } else {
              resolve({
                success: false
              })
            }
          }
          
          input.onclick = () => {
            // 清空之前的值，确保可以重复选择同一个文件
            input.value = ''
          }
          
          input.click()
        })
      }
    } catch (error) {
      return {
        success: false,
        error: error as string
      }
    }
  }

  /**
   * 获取文件的 URL，用于在浏览器中显示
   */
  static async getFileUrl(filePath: string): Promise<string | null> {
    try {
      // 检查是否在 Tauri 环境中
      if (typeof window !== 'undefined' && (window as any).__TAURI__) {
        // 在 Tauri 环境中，转换文件路径为可访问的 URL
        const { convertFileSrc } = await import('@tauri-apps/api/core')
        return convertFileSrc(filePath)
      } else {
        // 在普通 web 环境中，文件路径就是 blob URL 或 data URL
        return filePath
      }
    } catch (error) {
      console.error('获取文件 URL 失败:', error)
      return null
    }
  }

  /**
   * 检查文件是否为图片类型
   */
  static isImageFile(fileName: string): boolean {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg']
    const extension = fileName.split('.').pop()?.toLowerCase()
    return extension ? imageExtensions.includes(extension) : false
  }

  /**
   * 格式化文件大小
   */
  static formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes'
    
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }
}