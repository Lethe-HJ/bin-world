import cv2
import numpy as np
import os
import uuid
import time
import math
from pathlib import Path
from typing import Dict, List, Optional, Tuple

class ImageProcessor:
    def __init__(self, chunk_size: int = 512, min_size: int = 256):
        self.chunk_size = chunk_size
        self.min_size = min_size
        self.storage_dir = Path("storage")
        self.storage_dir.mkdir(exist_ok=True)
        
    def process_large_image(self, image_path: str) -> Dict:
        """处理大图像并生成多分辨率金字塔"""
        self.start_time = time.time()
        image_id = str(uuid.uuid4())
        
        # 创建图像存储目录
        image_dir = self.storage_dir / image_id
        image_dir.mkdir(exist_ok=True)
        
        # 读取原始图像
        original_image = cv2.imread(image_path)
        if original_image is None:
            raise ValueError(f"Failed to load image: {image_path}")
            
        # 生成图像金字塔
        pyramid_levels = self.generate_pyramid(original_image)
        
        # 分割成chunks并保存
        chunks_data = self.split_into_chunks(pyramid_levels, image_dir)
        
        # 生成并保存元数据
        metadata = self.generate_metadata(chunks_data, image_id)
        self._save_metadata(image_id, metadata)
        
        return metadata
        
    def generate_pyramid(self, image: np.ndarray) -> List[Dict]:
        """生成图像金字塔"""
        levels = []
        current = image.copy()
        level = 0
        
        while min(current.shape[0], current.shape[1]) > self.min_size:
            levels.append({
                'level': level,
                'width': current.shape[1],
                'height': current.shape[0],
                'scale': 1.0 / (2 ** level),
                'image': current.copy()
            })
            
            # 生成下一级（50%缩放）
            current = cv2.resize(
                current,
                (current.shape[1] // 2, current.shape[0] // 2),
                interpolation=cv2.INTER_LANCZOS4
            )
            level += 1
            
        return levels
        
    def split_into_chunks(self, pyramid_levels: List[Dict], image_dir: Path) -> Dict[int, List[Dict]]:
        """将每个金字塔级别分割成chunks"""
        chunks = {}
        
        for level_data in pyramid_levels:
            level = level_data['level']
            image = level_data['image']
            level_dir = image_dir / str(level)
            level_dir.mkdir(exist_ok=True)
            
            height, width = image.shape[:2]
            chunks[level] = []
            
            # 计算chunk网格
            chunks_x = math.ceil(width / self.chunk_size)
            chunks_y = math.ceil(height / self.chunk_size)
            
            for y in range(chunks_y):
                for x in range(chunks_x):
                    # 计算实际的chunk区域
                    start_x = x * self.chunk_size
                    start_y = y * self.chunk_size
                    end_x = min(start_x + self.chunk_size, width)
                    end_y = min(start_y + self.chunk_size, height)
                    
                    # 提取chunk
                    chunk_data = image[start_y:end_y, start_x:end_x]
                    
                    # 保存chunk
                    chunk_filename = f"{x}_{y}.png"
                    chunk_path = level_dir / chunk_filename
                    cv2.imwrite(str(chunk_path), chunk_data)
                    
                    chunk_info = {
                        'level': level,
                        'x': x,
                        'y': y,
                        'width': end_x - start_x,
                        'height': end_y - start_y,
                        'filename': chunk_filename
                    }
                    chunks[level].append(chunk_info)
            
        return chunks
        
    def generate_metadata(self, chunks_data: Dict[int, List[Dict]], image_id: str) -> Dict:
        """生成图像元数据"""
        levels = []
        total_chunks = 0
        
        for level, chunk_list in chunks_data.items():
            if not chunk_list:
                continue
                
            # 计算该级别的总尺寸
            max_x = max(chunk['x'] for chunk in chunk_list)
            max_y = max(chunk['y'] for chunk in chunk_list)
            
            # 找到最后一个chunk的实际尺寸
            last_chunk = next(
                (c for c in chunk_list if c['x'] == max_x and c['y'] == max_y),
                chunk_list[0]
            )
            
            level_width = max_x * self.chunk_size + last_chunk['width']
            level_height = max_y * self.chunk_size + last_chunk['height']
            
            level_metadata = {
                'level': level,
                'width': level_width,
                'height': level_height,
                'scale': 1.0 / (2 ** level),
                'chunk_size': self.chunk_size,
                'chunks_x': max_x + 1,
                'chunks_y': max_y + 1,
                'chunk_count': len(chunk_list)
            }
            
            levels.append(level_metadata)
            total_chunks += len(chunk_list)
        
        return {
            'image_id': image_id,
            'levels': sorted(levels, key=lambda x: x['level']),
            'total_chunks': total_chunks,
            'chunk_size': self.chunk_size,
            'processing_time': time.time() - self.start_time
        }
        
    def _save_metadata(self, image_id: str, metadata: Dict) -> None:
        """保存元数据到文件"""
        metadata_path = self.storage_dir / image_id / "metadata.json"
        import json
        with open(metadata_path, 'w') as f:
            json.dump(metadata, f, indent=2)
            
    def get_chunk(self, image_id: str, level: int, x: int, y: int) -> Optional[bytes]:
        """获取指定的图像块"""
        chunk_path = self.storage_dir / image_id / str(level) / f"{x}_{y}.png"
        if not chunk_path.exists():
            return None
            
        with open(chunk_path, 'rb') as f:
            return f.read()
            
    def get_metadata(self, image_id: str) -> Optional[Dict]:
        """获取图像元数据"""
        metadata_path = self.storage_dir / image_id / "metadata.json"
        if not metadata_path.exists():
            return None
            
        import json
        with open(metadata_path, 'r') as f:
            return json.load(f)
