# Agent 2 Task Manifest: Performance & Optimization Guru

**Agent:** 2
**Role:** Performance & Optimization Guru
**Sprint:** July 14-25, 2025

This document outlines your tasks for the two-week code audit and remediation sprint. Your primary focus is on identifying and addressing performance bottlenecks to ensure the HealthAI-2030 application is fast, responsive, and efficient.

## Week 1: Audit and Analysis (July 14-18)

| Task ID | Description | Deliverables |
| --- | --- | --- |
| PERF-001 | **Performance Profiling:** Profile the application on all target platforms (iOS, macOS, watchOS, tvOS) using Instruments. Focus on the Time Profiler to identify CPU-intensive operations and the GPU Driver instrument to analyze rendering performance. | A report detailing performance hotspots for each platform. The report should include screenshots from Instruments, method names responsible for high CPU/GPU usage, and initial hypotheses for optimization. |
| PERF-002 | **Memory Leak Detection:** Use the Leaks and Allocations instruments to detect and analyze memory leaks and abandoned memory. Pay special attention to retain cycles in closures and delegates. | A list of identified memory leaks with stack traces and proposed fixes. For each leak, provide the object graph and an explanation of the retain cycle. |
| PERF-003 | **App Launch Time Optimization:** Use the "App Launch" template in Instruments to analyze and optimize the application's launch time. Measure both cold and warm launch times. | A report on launch time metrics before and after optimization. The report should detail the phases of the app launch and identify the specific code paths that are causing delays. |
| PERF-004 | **Energy Consumption Analysis:** Use the Energy Log instrument to profile the app's energy impact. Identify areas of high CPU usage, network activity, and GPS usage that could be optimized to reduce battery drain. | A report on energy consumption with recommendations for reducing it. The report should highlight the most energy-intensive parts of the app and suggest specific changes (e.g., batching network requests, using more efficient APIs). |

## Week 2: Remediation and Implementation (July 21-25)

Based on the findings from Week 1, you will spend this week implementing the necessary optimizations.

| Task ID | Description |
| --- | --- |
| PERF-FIX-001 | **Optimize CPU/GPU Hotspots:** Apply optimizations to the identified performance hotspots. This could involve algorithm improvements, moving work to background threads, or optimizing graphics assets. |
| PERF-FIX-002 | **Fix Memory Leaks:** Implement the proposed fixes for all identified memory leaks. |
| PERF-FIX-003 | **Implement Launch Time Optimizations:** Apply the changes to improve the application's launch time. |
| PERF-FIX-004 | **Reduce Energy Consumption:** Implement the recommendations to reduce the app's energy impact. |

Submit all changes as pull requests for review. Good luck!
