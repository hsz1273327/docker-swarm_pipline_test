FROM --platform=$TARGETPLATFORM golang:1.15-alpine as build_bin
ENV GO111MODULE=on
ENV GOPROXY=https://goproxy.io
ENV CGO_ENABLED=0
WORKDIR /code
ADD go.mod /code/go.mod
ADD go.sum /code/go.sum
ADD main.go /code/main.go
RUN go build -ldflags "-s -w" -o docker-swarm_pipline_test-go main.go

FROM --platform=$TARGETPLATFORM alpine:3.11 as upx
WORKDIR /code
# 安装upx
#RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
RUN apk update && apk add --no-cache upx && rm -rf /var/cache/apk/*
COPY --from=build_bin /code/docker-swarm_pipline_test-go .
RUN upx --best --lzma -o docker-swarm_pipline_test docker-swarm_pipline_test-go

FROM --platform=$TARGETPLATFORM alpine:3.14.0 as build_upximg
#RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
RUN apk update && apk --no-cache add curl && rm -rf /var/cache/apk/*
COPY --from=upx /code/docker-swarm_pipline_test .
RUN chmod +x /docker-swarm_pipline_test
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD [ "curl","-f","http://localhost:5000/ping" ]
CMD [ "/docker-swarm_pipline_test"]