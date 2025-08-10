# 大图像 LOD 渲染方案 - 高级特性

## Chunk 管理系统

### 1. 内存分层管理

```typescript
class MemoryManager {
    private readonly CHUNK_SIZE = 512;
    private readonly BYTES_PER_PIXEL = 4; // RGBA
    private readonly BASE_CHUNK_MEMORY = this.CHUNK_SIZE * this.CHUNK_SIZE * this.BYTES_PER_PIXEL;
    
    // 内存限制
    private readonly CPU_MEMORY_LIMIT = 200 * 1024 * 1024; // 200MB
    private readonly GPU_MEMORY_LIMIT = 500 * 1024 * 1024; // 500MB
    private readonly GPU_TEXTURE_LIMIT = 1000; // 最大纹理数量
    
    // 当前使用的内存
    private cpuMemoryUsed = 0;
    private gpuMemoryUsed = 0;
    private gpuTextureCount = 0;
    
    // LRU缓存
    private lruList: ChunkMetadata[] = [];
    
    constructor(private gl: WebGL2RenderingContext) {
        // 定期检查内存使用情况
        setInterval(() => this.checkMemoryUsage(), 5000);
    }
    
    async allocateMemory(chunk: ChunkMetadata, buffer: ArrayBuffer): Promise<boolean> {
        const memoryNeeded = this.calculateMemoryNeeded(chunk);
        
        // 检查是否有足够的CPU内存
        if (this.cpuMemoryUsed + memoryNeeded > this.CPU_MEMORY_LIMIT) {
            await this.freeCPUMemory(memoryNeeded);
        }
        
        // 分配CPU内存
        try {
            chunk.buffer = buffer;
            chunk.size = memoryNeeded;
            chunk.state = ChunkState.CPU_MEMORY;
            this.cpuMemoryUsed += memoryNeeded;
            this.updateLRU(chunk);
            return true;
        } catch (error) {
            console.error('Failed to allocate CPU memory:', error);
            return false;
        }
    }
    
    async allocateGPUMemory(chunk: ChunkMetadata): Promise<boolean> {
        if (!chunk.buffer || chunk.state !== ChunkState.CPU_MEMORY) {
            return false;
        }
        
        // 检查GPU限制
        if (this.gpuTextureCount >= this.GPU_TEXTURE_LIMIT ||
            this.gpuMemoryUsed + chunk.size > this.GPU_MEMORY_LIMIT) {
            await this.freeGPUMemory(chunk.size);
        }
        
        // 创建纹理
        try {
            const texture = this.gl.createTexture();
            this.gl.bindTexture(this.gl.TEXTURE_2D, texture);
            
            // 上传数据到GPU
            this.gl.texImage2D(
                this.gl.TEXTURE_2D,
                0,
                this.gl.RGBA,
                this.CHUNK_SIZE,
                this.CHUNK_SIZE,
                0,
                this.gl.RGBA,
                this.gl.UNSIGNED_BYTE,
                new Uint8Array(chunk.buffer)
            );
            
            // 设置纹理参数
            this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_MIN_FILTER, this.gl.LINEAR);
            this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_MAG_FILTER, this.gl.LINEAR);
            this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_WRAP_S, this.gl.CLAMP_TO_EDGE);
            this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_WRAP_T, this.gl.CLAMP_TO_EDGE);
            
            // 更新状态
            chunk.texture = texture;
            chunk.state = ChunkState.GPU_TEXTURE;
            this.gpuMemoryUsed += chunk.size;
            this.gpuTextureCount++;
            this.updateLRU(chunk);
            
            return true;
        } catch (error) {
            console.error('Failed to allocate GPU memory:', error);
            return false;
        }
    }
}

### 2. 视锥体剔除

```typescript
class FrustumCuller {
    private frustumPlanes: Float32Array; // 视锥体的6个平面
    
    updateFrustum(viewProjectionMatrix: Float32Array) {
        this.frustumPlanes = this.extractFrustumPlanes(viewProjectionMatrix);
    }
    
    isChunkVisible(chunk: ChunkMetadata, levelData: LevelInfo): boolean {
        // 计算chunk的包围盒
        const scale = levelData.scale;
        const chunkSize = levelData.chunk_size;
        
        const minX = chunk.x * chunkSize * scale;
        const minY = chunk.y * chunkSize * scale;
        const maxX = minX + chunkSize * scale;
        const maxY = minY + chunkSize * scale;
        
        // 检查包围盒是否与视锥体相交
        return this.intersectsFrustum(minX, minY, maxX, maxY);
    }
    
    private intersectsFrustum(minX: number, minY: number, maxX: number, maxY: number): boolean {
        // 对每个平面进行测试
        for (let i = 0; i < 6; i++) {
            const plane = this.frustumPlanes.subarray(i * 4, (i + 1) * 4);
            
            // 检查包围盒是否完全在平面的负面
            const px = plane[0] > 0 ? maxX : minX;
            const py = plane[1] > 0 ? maxY : minY;
            
            if (px * plane[0] + py * plane[1] + plane[3] < 0) {
                return false;
            }
        }
        
        return true;
    }
}
```

### 3. 预测性加载

```typescript
class ChunkPredictor {
    private movementHistory: Array<{x: number, y: number, zoom: number, timestamp: number}> = [];
    private historyLimit = 10;
    private predictionWindow = 500; // 预测未来500ms
    
    recordMovement(x: number, y: number, zoom: number) {
        this.movementHistory.push({
            x, y, zoom,
            timestamp: Date.now()
        });
        
        if (this.movementHistory.length > this.historyLimit) {
            this.movementHistory.shift();
        }
    }
    
    predictNextChunks(): Array<{level: number, x: number, y: number, priority: number}> {
        if (this.movementHistory.length < 2) {
            return [];
        }
        
        // 计算速度和加速度
        const velocities = this.calculateVelocities();
        const acceleration = this.calculateAcceleration(velocities);
        
        // 预测未来位置
        const latest = this.movementHistory[this.movementHistory.length - 1];
        const predictedPosition = this.predictPosition(
            latest,
            velocities[velocities.length - 1],
            acceleration
        );
        
        // 根据预测位置确定需要的chunks
        return this.getChunksForPosition(predictedPosition);
    }
    
    private getChunksForPosition(position: {x: number, y: number, zoom: number}) {
        const level = Math.max(0, Math.floor(-Math.log2(position.zoom)));
        const scale = Math.pow(2, -level);
        const chunkSize = 512 * scale;
        
        // 计算中心chunk
        const centerX = Math.floor(position.x / chunkSize);
        const centerY = Math.floor(position.y / chunkSize);
        
        // 生成周围的chunks，优先级随距离降低
        const chunks: Array<{level: number, x: number, y: number, priority: number}> = [];
        const radius = 2; // 预加载半径
        
        for (let dy = -radius; dy <= radius; dy++) {
            for (let dx = -radius; dx <= radius; dx++) {
                const distance = Math.sqrt(dx * dx + dy * dy);
                const priority = Math.max(0, 1 - distance / radius);
                
                chunks.push({
                    level,
                    x: centerX + dx,
                    y: centerY + dy,
                    priority
                });
            }
        }
        
        return chunks.sort((a, b) => b.priority - a.priority);
    }
}
```

## 性能优化策略

### 1. 内存分层管理
- CPU内存限制：200MB
- GPU内存限制：500MB
- 最大纹理数量：1000个
- 使用LRU策略进行内存回收

### 2. 并行加载优化
- WebWorker处理所有chunk请求
- 最大并发请求数：6
- 使用ArrayBuffer转移避免复制
- 请求优先级队列

### 3. 预测性能优化
- 记录用户最近10次移动
- 预测500ms内的位置
- 根据距离计算加载优先级
- 2层预加载半径

### 4. 视锥体剔除优化
- 视图矩阵提取6个平面
- 包围盒快速剔除
- 动态LOD级别选择
- 边缘chunk特殊处理

## 关键技术参数

### 推荐配置
- Chunk大小: 512x512 像素
- 内存限制: 
  - CPU: 200MB
  - GPU: 500MB
- 并发请求: 6
- 预测窗口: 500ms
- 预加载半径: 2 chunks

### 性能目标
- 渲染帧率: 60 FPS
- 最大加载延迟: 100ms
- 内存使用率: <80%
- 缓存命中率: >90%
