# syntax=docker/dockerfile:1
FROM swift:5.10 as build
WORKDIR /app
COPY . .
RUN swift build -c release

FROM swift:5.10-slim
WORKDIR /app
COPY --from=build /app/.build/release /app
CMD ["./HealthAI_2030App"]
