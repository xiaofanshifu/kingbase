FROM kylinos:latest
LABEL maintainer="thissuper" \
      version="V008R003C002B0290" \
      description="KingbaseES for arm architecture."
RUN useradd -U -m -d /home/kingbase -s /bin/bash kingbase
WORKDIR /home/kingbase
ADD Server.tgz ./kdb/
COPY ./docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh && chown -R kingbase:kingbase /home/kingbase
ENV PATH=/home/kingbase/kdb/Server/bin:$PATH DB_VERSION=V008R003C002B0100
VOLUME ["/home/kingbase/data"]
USER kingbase
EXPOSE 54321
ENTRYPOINT ["/home/kingbase/docker-entrypoint.sh"]
