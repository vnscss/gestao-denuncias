from core.request_data.collector import RequestDataCollector


class RequestDataMixin:

    def dispatch(self, request, *args, **kwargs):
        request.request_data = RequestDataCollector.collect(request)

        return super().dispatch(request, *args, **kwargs)
