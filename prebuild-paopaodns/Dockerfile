FROM alpine:edge AS builder
COPY build.sh /src/
RUN sh /src/build.sh
# JUST CHECK
RUN cp /src/mosdns /tmp/
RUN cp /src/unbound /tmp/
RUN cp /src/unbound-checkconf /tmp/
FROM scratch
COPY --from=builder /src/ /src/
