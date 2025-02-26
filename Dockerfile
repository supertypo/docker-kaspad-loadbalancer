FROM supertypo/kaspad:latest AS kaspad
FROM supertypo/kcheck:latest AS kcheck

FROM haproxy:lts-alpine

EXPOSE 16111
EXPOSE 16110
EXPOSE 17110

ARG VERSION=local

ENV PATH=/app:$PATH \
  VERSION=$VERSION

WORKDIR /app

USER root

COPY --from=kaspad /app/kaspactl /app/
COPY is-synced-grpc.sh /app/
COPY is-synced-grpc.sh /app/is-synced.sh
RUN chmod 755 /app/is-synced-grpc.sh /app/is-synced.sh

RUN apk --no-cache add libgcc
COPY --from=kcheck /usr/local/bin/kcheck /app/
COPY is-synced-wrpc.sh /app/
RUN chmod 755 /app/is-synced-wrpc.sh

COPY haproxy.cfg /app/

USER haproxy

CMD ["/usr/local/sbin/haproxy", "-f", "/app/haproxy.cfg"]
