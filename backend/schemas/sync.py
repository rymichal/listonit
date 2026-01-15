from datetime import datetime
from typing import Any, List, Literal
from pydantic import BaseModel


SyncActionType = Literal["create_list", "create_item", "update_list", "update_item", "delete_list", "delete_item"]
SyncEntityType = Literal["list", "item"]


class SyncAction(BaseModel):
    """A single sync action from the client"""
    id: str
    type: SyncActionType
    entity_type: SyncEntityType
    entity_id: str
    payload: dict[str, Any]
    client_timestamp: datetime


class BatchSyncRequest(BaseModel):
    """Request containing multiple sync actions"""
    actions: List[SyncAction]


class SyncResultItem(BaseModel):
    """Result of processing a single sync action"""
    action_id: str
    success: bool
    entity_type: SyncEntityType
    entity_id: str
    error: str | None = None
    conflict: dict[str, Any] | None = None


class BatchSyncResponse(BaseModel):
    """Response from batch sync endpoint"""
    results: List[SyncResultItem]
    server_timestamp: datetime
    synced_count: int
    failed_count: int
    conflict_count: int
