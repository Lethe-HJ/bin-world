from robyn import Robyn
from robyn.robyn import Response, Request
import json
import os
from image_processor import ImageProcessor

app = Robyn(__file__)
processor = ImageProcessor()

@app.post("/api/process-image")
async def process_image(request: Request):
    """处理大图像并返回元数据"""
    try:
        data = request.json()
        file_path = data.get('file_path')
        
        if not file_path or not os.path.exists(file_path):
            return Response(
                status_code=400,
                content=json.dumps({
                    "status": "error",
                    "message": "Invalid file path"
                }),
                headers={"Content-Type": "application/json"}
            )
        
        metadata = processor.process_large_image(file_path)
        
        return Response(
            status_code=200,
            content=json.dumps({
                "status": "success",
                **metadata
            }),
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        return Response(
            status_code=500,
            content=json.dumps({
                "status": "error",
                "message": str(e)
            }),
            headers={"Content-Type": "application/json"}
        )

@app.get("/api/chunk/:image_id/:level/:x/:y")
async def get_chunk(request: Request):
    """获取特定的图像块"""
    try:
        image_id = request.path_params['image_id']
        level = int(request.path_params['level'])
        x = int(request.path_params['x'])
        y = int(request.path_params['y'])
        
        chunk_data = processor.get_chunk(image_id, level, x, y)
        
        if chunk_data is None:
            return Response(
                status_code=404,
                content=json.dumps({
                    "status": "error",
                    "message": "Chunk not found"
                }),
                headers={"Content-Type": "application/json"}
            )
        
        return Response(
            content=chunk_data,
            headers={
                "Content-Type": "image/png",
                "Cache-Control": "public, max-age=31536000",
                "ETag": f'"{image_id}-{level}-{x}-{y}"',
                "Access-Control-Allow-Origin": "*"
            }
        )
    except Exception as e:
        return Response(
            status_code=500,
            content=json.dumps({
                "status": "error",
                "message": str(e)
            }),
            headers={"Content-Type": "application/json"}
        )

@app.get("/api/image/:image_id/info")
async def get_image_info(request: Request):
    """获取图像元数据信息"""
    try:
        image_id = request.path_params['image_id']
        metadata = processor.get_metadata(image_id)
        
        if metadata is None:
            return Response(
                status_code=404,
                content=json.dumps({
                    "status": "error",
                    "message": "Image metadata not found"
                }),
                headers={"Content-Type": "application/json"}
            )
        
        return Response(
            content=json.dumps(metadata),
            headers={"Content-Type": "application/json"}
        )
    except Exception as e:
        return Response(
            status_code=500,
            content=json.dumps({
                "status": "error",
                "message": str(e)
            }),
            headers={"Content-Type": "application/json"}
        )

if __name__ == "__main__":
    app.start(port=8080)