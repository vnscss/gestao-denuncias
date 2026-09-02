from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any


@dataclass
class RequestData:
    ip: str | None = None
    user: Any = None
    method: str | None = None
    path: str | None = None
    query_params: dict = field(default_factory=dict)
    headers: dict = field(default_factory=dict)
    cookies: dict = field(default_factory=dict)
    user_agent: str | None = None
    referer: str | None = None
    timestamp: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
