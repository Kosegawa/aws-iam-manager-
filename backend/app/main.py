from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .api.routes import router
from .config import settings

app = FastAPI(
    title="AWS IAM Manager API",
    description="複数のAWSアカウントのIAMユーザーを一元管理するAPI",
    version="1.0.0"
)

# CORS設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.get_cors_origins(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# APIルーターを登録
app.include_router(router, prefix="/api")


@app.get("/")
async def root():
    return {
        "message": "AWS IAM Manager API",
        "version": "1.0.0",
        "docs": "/docs"
    }
