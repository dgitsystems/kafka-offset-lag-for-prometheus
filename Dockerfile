FROM golang:1.13
LABEL maintainer "https://hub.docker.com/u/pceric/"
WORKDIR /go/src/kafka-offset-lag-for-prometheus
RUN go get -v -u "github.com/Shopify/sarama" \
              "github.com/kouhin/envflag" \
              "github.com/prometheus/client_golang/prometheus" \
              "github.com/prometheus/client_golang/prometheus/promhttp" \
              "github.com/xdg/scram"
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-w -s" -o app

FROM scratch

ARG project
ARG description
ARG BUILD_DATE
ARG BUILD_VERSION
ARG VCS_URL
ARG VCS_REF

ENV SERVICE $project
ENV VERSION $BUILD_VERSION

COPY --from=0 /go/src/kafka-offset-lag-for-prometheus/app /kafka-offset-lag-for-prometheus

USER 1000

ENTRYPOINT ["/kafka-offset-lag-for-prometheus"]

# Because this command uses $BUILD_DATE it will always invalidate the cache - keep at the bottom
# https://github.com/opencontainers/image-spec/blob/master/annotations.md
LABEL org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.title=$project \
      org.opencontainers.image.description=$description \
      org.opencontainers.image.source=$VCS_URL \
      org.opencontainers.image.revision=$VCS_REF \
      org.opencontainers.image.vendor="DGIT Systems" \
      org.opencontainers.image.version=$BUILD_VERSION
