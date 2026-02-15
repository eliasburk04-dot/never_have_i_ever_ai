# 8. Scaling Strategy

## Phase 1: Launch (0–10k MAU) — Current

| Component | Solution | Cost |
|-----------|----------|------|
| Database | PostgreSQL 16 (Docker on Raspberry Pi) | $0 |
| Realtime | Socket.IO (integrated in Fastify) | $0 |
| API Server | Node.js + Fastify (Docker on Pi) | $0 |
| Reverse Proxy | Caddy (auto HTTPS) | $0 |
| AI | Groq Free Tier (14,400 req/day) | $0 |
| Purchases | StoreKit 2 (local verification) | $0 |
| **Total** | | **$0/month** |

### Limitations at This Scale
- Pi hardware: ~100–200 concurrent WebSocket connections
- 14,400 Groq req/day ≈ 720 full games of 20 rounds
- Single-node: no HA (acceptable for party game)
- Sufficient for launch + early growth

---

## Phase 2: Growth (10k–100k MAU)

| Component | Solution | Cost |
|-----------|----------|------|
| Database | PostgreSQL on VPS (Hetzner CX22) | €4/mo |
| API Server | Fastify on same VPS | included |
| Realtime | Socket.IO on same VPS | included |
| AI | Groq Developer Tier ($0.05/1M tokens) | ~$20/mo |
| Reverse Proxy | Caddy | included |
| **Total** | | **~$24/month** |

### Optimizations Applied
- Migrate from Pi to VPS for more CPU/RAM/bandwidth
- Question pool expansion (reduce AI calls by 40%)
- Aggressive client-side caching of pool questions
- Connection pooling for Postgres (pg-pool)

---

## Phase 3: Scale (100k+ MAU)

| Component | Solution | Cost |
|-----------|----------|------|
| Database | Managed Postgres (Neon/Hetzner) + read replicas | $50+ |
| API Server | Multiple Fastify instances behind load balancer | $30+ |
| Realtime | Socket.IO with Redis adapter (sticky sessions) | $10+ |
| AI | Groq paid tier or self-hosted LLaMA | $100–500 |
| **Total** | | **~$200–600/month** |

### Architecture Changes at Scale
1. **Redis** for Socket.IO adapter (multi-instance pub/sub)
2. **Read replicas** for question pool queries (high read volume)
3. **CDN** for question pool (pre-fetched per language/intensity)
4. **Groq fallback**: If Groq rate-limited, fallback to pool-only mode
5. **Horizontal scaling**: Multiple Fastify workers behind Caddy upstream

---

## Scaling Decision Matrix

```
IF concurrent_connections > 200:
    → Migrate from Pi to VPS

IF groq_daily_calls > 10,000:
    → Expand question pool (reduce AI dependency)
    → Implement response caching for similar game states

IF concurrent_connections > 1,000:
    → Add Redis adapter for Socket.IO
    → Scale to multiple Fastify instances

IF monthly_revenue > $2,500:
    → Consider managed Postgres for reliability

IF groq_monthly_cost > $200:
    → Evaluate self-hosted LLaMA
    → Or switch to Cerebras/Together.ai for cheaper inference
```

---

## Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| Round transition latency | < 500ms | Time from host advance to next question display |
| AI question generation | < 2s | API route → Groq → response |
| Lobby join | < 1s | Code entry to player list appearance |
| Answer submission | < 200ms | Button tap to server confirmation |
| App cold start | < 3s | Launch to Home screen |
| Realtime sync | < 100ms | State change to all clients updated |

---

## Monitoring & Observability

- **Docker logs**: `docker compose logs -f` for all services
- **Postgres**: `pg_stat_activity` for connection monitoring
- **Groq Dashboard**: API usage, latency, error rates
- **App Store Connect**: Revenue, sales, refund requests
- **Caddy access logs**: Request volume, error rates
