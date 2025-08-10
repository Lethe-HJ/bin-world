export interface FileInfo {
  name: string
  path: string
  size?: number
}

export interface FileDialogOptions {
  title?: string
  filters?: Array<{
    name: string
    extensions: string[]
  }>
  defaultName?: string
}

export interface FileDialogResult {
  success: boolean
  data?: FileInfo
  error?: string
}