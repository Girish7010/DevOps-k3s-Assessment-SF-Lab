import os
import random
import time
import logging
from typing import Optional

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel

import prometheus_client
from prometheus_client import Counter, Histogram, generate_latest

from opentelemetry import trace, metrics
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.resources import Resource
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.semconv.resource import ResourceAttributes

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("sample-api")

# Setup OpenTelemetry Tracing
resource = Resource(attributes={
    ResourceAttributes.SERVICE_NAME: "sample-api"
})
trace_provider = TracerProvider(resource=resource)
otlp_exporter = OTLPSpanExporter(endpoint=os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://tempo:4317"), insecure=True)
trace_provider.add_span_processor(BatchSpanProcessor(otlp_exporter))
trace.set_tracer_provider(trace_provider)
tracer = trace.get_tracer(__name__)

app = FastAPI(title="Sample DevOps API")

# Setup Prometheus Metrics
REQUEST_COUNT = Counter("api_requests_total", "Total count of requests by method and path", ["method", "path", "status"])
REQUEST_LATENCY = Histogram("api_request_latency_seconds", "Request latency", ["method", "path"])

@app.middleware("http")
async def prometheus_middleware(request: Request, call_next):
    start_time = time.time()
    method = request.method
    path = request.url.path
    
    # Exclude /metrics from metrics
    if path == "/metrics":
        return await call_next(request)
        
    try:
        response = await call_next(request)
        status_code = response.status_code
    except Exception as e:
        status_code = 500
        raise e
    finally:
        latency = time.time() - start_time
        REQUEST_COUNT.labels(method=method, path=path, status=status_code).inc()
        REQUEST_LATENCY.labels(method=method, path=path).observe(latency)
        
    return response

# Instrument FastAPI with OTel
FastAPIInstrumentor.instrument_app(app)

class Item(BaseModel):
    name: str
    description: Optional[str] = None
    price: float

@app.get("/")
async def root():
    logger.info("Handling root request")
    with tracer.start_as_current_span("root_handler"):
        return {"message": "Welcome to the Sample API!"}

@app.get("/health")
async def health():
    logger.info("Health check")
    return {"status": "healthy"}

@app.get("/metrics")
async def metrics():
    return prometheus_client.Response(generate_latest(), media_type="text/plain")

@app.get("/items/{item_id}")
async def read_item(item_id: int):
    logger.info(f"Fetching item {item_id}")
    with tracer.start_as_current_span("fetch_item") as span:
        span.set_attribute("item.id", item_id)
        if item_id == 0:
            logger.error("Item 0 not found")
            span.set_attribute("error", True)
            raise HTTPException(status_code=404, detail="Item not found")
        time.sleep(random.uniform(0.01, 0.1)) # simulate DB call
        return {"item_id": item_id, "name": f"Item {item_id}"}

@app.post("/items")
async def create_item(item: Item):
    logger.info(f"Creating item: {item.name}")
    with tracer.start_as_current_span("create_item") as span:
        span.set_attribute("item.name", item.name)
        span.set_attribute("item.price", item.price)
        if item.price < 0:
            logger.warning("Attempted to create item with negative price")
            raise HTTPException(status_code=400, detail="Price must be positive")
        return item

@app.get("/error")
async def generate_error():
    logger.error("Intentional error generated")
    with tracer.start_as_current_span("generate_error") as span:
        span.set_attribute("error", True)
        raise HTTPException(status_code=500, detail="Internal Server Error")
