ARG LIQUIDSOAP_VERSION=2.4.0
FROM savonet/liquidsoap:v${LIQUIDSOAP_VERSION}

ARG TARGETARCH

USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends wget libmagickwand-6.q16-6 \
 && apt-get remove -y wget \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

USER liquidsoap
