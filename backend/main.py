from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import create_tables
from routes.auth import router as auth_router
from routes.admin import router as admin_router
from routes.tenders import router as tenders_router
from routes.auctions import router as auctions_router
from routes.websocket import router as websocket_router
import uvicorn

app = FastAPI(
    title="LogiQ API",
    description="Reverse Auction System for Transport Procurement",
    version="1.0.0"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(auth_router)
app.include_router(admin_router)
app.include_router(tenders_router)
app.include_router(auctions_router)
app.include_router(websocket_router)

@app.on_event("startup")
def on_startup():
    create_tables()

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/")
def root():
    return {
        "message": "LogiQ Reverse Auction API is running",
        "version": "1.0.0",
        "roles": ["admin", "user", "transporter"]
    }

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
