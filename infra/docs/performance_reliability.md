# Database & Backend Performance Tuning

- Use indexes on all time-series and user ID columns
- Profile slow queries with EXPLAIN ANALYZE
- Use connection pooling for database access
- Cache frequent queries in memory (e.g., Redis)
- Monitor query latency and error rates

# Backup & Disaster Recovery

- Nightly automated database backups (retain 30 days)
- Store backups in a separate region/cloud
- Test restore procedures quarterly
- Document recovery time objectives (RTO) and recovery point objectives (RPO)

# High-Availability Architecture

- Deploy across multiple availability zones
- Use managed load balancers (e.g., AWS ALB)
- Auto-scale application pods based on CPU/memory
- Health checks and self-healing for all services
