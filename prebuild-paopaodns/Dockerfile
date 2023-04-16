FROM alpine:edge
COPY build.sh /src/
RUN sh /src/build.sh
# JUST CHECK
RUN cp /src/mosdns /tmp/ &&\
cp /src/unbound /tmp/ &&\
cp /src/unbound-checkconf /tmp/