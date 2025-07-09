#!/bin/bash
cd "$(dirname "$0")"
git add .
git commit -m "Automated update $(date '+%Y-%m-%d %H:%M:%S')"
git push origin ios18-optimization
