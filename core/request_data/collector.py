from core.request_data.data import RequestData

SENSITIVE_HEADERS = {
    'Authorization',
    'Cookie',
    'X-CSRFToken',
}


class RequestDataCollector:

    @classmethod
    def collect(cls, request) -> RequestData:
        return RequestData(
            ip=cls._get_ip(request),
            user=request.user if request.user.is_authenticated else None,
            method=request.method,
            path=request.path,
            query_params=request.GET.dict(),
            headers=cls._sanitize_headers(request.headers),
            cookies=dict(request.COOKIES),
            user_agent=request.headers.get('User-Agent'),
            referer=request.headers.get('Referer'),
        )

    @staticmethod
    def _get_ip(request) -> str | None:
        forwarded = request.META.get('HTTP_X_FORWARDED_FOR')

        if forwarded:
            return forwarded.split(',')[0].strip()

        return request.META.get('REMOTE_ADDR')

    @classmethod
    def _sanitize_headers(cls, headers) -> dict:
        sanitized = {}

        for key, value in headers.items():
            if key in SENSITIVE_HEADERS:
                sanitized[key] = '********'
            else:
                sanitized[key] = value

        return sanitized
