FROM sonarqube:8.5.0-community

USER root

RUN apk add --no-cache wget
COPY resources/healthcheck /usr/local/bin/

USER sonarqube

RUN mkdir /opt/sonarqube/backup

COPY plugins/ /opt/sonarqube/extensions/plugins/
COPY plugins/ /opt/sonarqube/lib/common/

HEALTHCHECK CMD ["healthcheck"]
