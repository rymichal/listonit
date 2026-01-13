from fastapi import APIRouter

from api.v1.endpoints import lists

api_router = APIRouter(prefix="/api/v1")

api_router.include_router(lists.router)
