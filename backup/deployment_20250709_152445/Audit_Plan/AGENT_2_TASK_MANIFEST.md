# Agent 2 Task Manifest: Performance & Optimization Guru

**Agent:** 2
**Role:** Performance & Optimization Guru
**Sprint:** July 14-25, 2025
**Version:** 2.0

This document outlines your expanded tasks for the two-week code audit and remediation sprint. Your primary focus is on deep performance analysis and optimization to ensure the HealthAI-2030 application is exceptionally fast, responsive, and efficient.

## Week 1: Deep Audit and Strategic Analysis (July 14-18)

| Task ID | Description | Deliverables |
| --- | --- | --- |
| PERF-001 | **Multi-Platform Performance Profiling:** Conduct in-depth performance profiling on all target platforms using Instruments. Analyze CPU, GPU, memory, and I/O performance. Use MetricKit to gather real-world performance data. | A comprehensive report detailing performance bottlenecks on each platform, with specific focus on areas like UI rendering, data processing, and background tasks. |
| PERF-002 | **Advanced Memory Leak Detection & Analysis:** Use the Leaks, Allocations, and VM Tracker instruments to perform a deep analysis of memory usage. Identify not just leaks but also memory bloat and inefficient memory usage patterns. | A detailed list of all identified memory issues, including retain cycles, abandoned memory, and excessive memory consumption, with clear explanations and proposed solutions. |
| PERF-003 | **App Launch Time & Responsiveness Optimization:** Analyze and optimize the app's launch time and UI responsiveness. Identify and defer non-essential tasks, and optimize the main thread's workload. | A report on launch time and UI responsiveness metrics, with a list of implemented optimizations, such as code splitting and lazy loading of components. |
| PERF-004 | **Energy Consumption & Network Payload Analysis:** Profile the app's energy impact and analyze network traffic to identify large or frequent requests. Look for opportunities to reduce data payloads and batch requests. | A report on energy and data consumption, with recommendations for reducing both. This should include suggestions for more efficient data formats (e.g., Protocol Buffers). |
| PERF-005 | **Database Query and Asset Optimization:** Analyze Core Data fetch requests and identify slow or inefficient queries. Audit all image and data assets for potential size reductions. | A set of optimized database queries and a plan for compressing and optimizing all application assets. |

## Week 2: Intensive Remediation and Implementation (July 21-25)

| Task ID | Description |
| --- | --- |
| PERF-FIX-001 | **Optimize Performance Bottlenecks:** Apply the identified optimizations to improve CPU, GPU, and I/O performance. |
| PERF-FIX-002 | **Resolve Memory Issues:** Implement the proposed fixes for all identified memory leaks and memory consumption issues. |
| PERF-FIX-003 | **Enhance App Responsiveness:** Implement the optimizations to improve app launch time and UI responsiveness. |
| PERF-FIX-004 | **Reduce Energy and Data Usage:** Implement the recommendations to reduce the app's energy and data impact. |
| PERF-FIX-005 | **Implement Database and Asset Optimizations:** Apply the optimized database queries and compress all application assets. |

Submit all changes as pull requests for peer review.
