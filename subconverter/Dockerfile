ARG SUBCONVERTER_TAG=latest
FROM tindy2013/subconverter:${SUBCONVERTER_TAG}

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR /base
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["subconverter"]

EXPOSE 25500
