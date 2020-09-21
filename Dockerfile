FROM sonarqube:8.1-community-beta

USER root

RUN apt-get update -y && apt-get install wget -y
COPY resources/healthcheck /usr/local/bin/

USER sonarqube

RUN mkdir /opt/sonarqube/backup

COPY plugins/ /opt/sq/extensions/plugins/
COPY plugins/ /opt/sq/lib/common/

HEALTHCHECK CMD ["healthcheck"]
