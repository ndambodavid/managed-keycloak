FROM quay.io/phasetwo/keycloak-crdb:26.0.5 as builder

ENV KC_METRICS_ENABLED=true
ENV KC_HEALTH_ENABLED=true
ENV KC_FEATURES=preview,persistent-user-sessions
# ENV KC_HTTP_RELATIVE_PATH=/auth
ENV PROXY_ADDRESS_FORWARDING=true
ENV KC_BOOTSTRAP_ADMIN_USERNAME=admin
ENV KC_BOOTSTRAP_ADMIN_PASSWORD=password
ENV KC_DB=postgres
ENV KC_DB_URL_HOST=10.0.0.227
ENV KC_DB_URL_DATABASE=keycloak
ENV KC_DB_SCHEMA=public
ENV KC_DB_USERNAME=keyuser
ENV KC_DB_PASSWORD=keypass
ENV KC_HOSTNAME=keycloak.paykit.africa
ENV KC_HOSTNAME_STRICT=false
ENV KC_HTTP_ENABLED=true
ENV KC_HTTP_MANAGEMENT_PORT=9000
ENV KC_LOG_LEVEL=INFO
ENV KC_PROXY=edge
ENV KC_TRANSACTION_JTA_ENABLED=false
ENV KC_TRANSACTION_XA_ENABLED=false



# jdbc_ping infinispan configuration
COPY ./conf/cache-ispn-jdbc-ping.xml /opt/keycloak/conf/cache-ispn-jdbc-ping.xml

# custom keycloak.conf
#COPY ./conf/keycloak.conf /opt/keycloak/conf/keycloak.conf
#COPY ./conf/quarkus.properties /opt/keycloak/conf/quarkus.properties

# 3rd party themes and extensions
COPY ./libs/ext/*.jar /opt/keycloak/providers/
#COPY ./libs/target/container*/*.jar /opt/keycloak/providers/

RUN /opt/keycloak/bin/kc.sh --verbose build #--spi-email-template-provider=freemarker-plus-mustache --spi-email-template-freemarker-plus-mustache-enabled=true --spi-theme-cache-themes=false

FROM quay.io/phasetwo/keycloak-crdb:26.0.5

#USER root
# remediation for vulnerabilities
# no longer works after switch to ubi-micro 
#RUN microdnf update -y && microdnf clean all && rm -rf /var/cache/yum/* && rm -f /tmp/tls-ca-bundle.pem

USER 1000

COPY --from=builder /opt/keycloak/lib/quarkus/ /opt/keycloak/lib/quarkus/
COPY --from=builder /opt/keycloak/providers/ /opt/keycloak/providers/
COPY --from=builder /opt/keycloak/conf/cache-ispn-jdbc-ping.xml /opt/keycloak/conf/cache-ispn-jdbc-ping.xml
# custom keycloak.conf
#COPY --from=builder /opt/keycloak/conf/quarkus.properties /opt/keycloak/conf/quarkus.properties
#COPY --from=builder /opt/keycloak/conf/keycloak.conf /opt/keycloak/conf/keycloak.conf

WORKDIR /opt/keycloak
# this cert shouldn't be used, as it's just to stop the startup from complaining
RUN keytool -genkeypair -storepass password -storetype PKCS12 -keyalg RSA -keysize 2048 -dname "CN=server" -alias server -ext "SAN:c=DNS:localhost,IP:127.0.0.1" -keystore conf/server.keystore

ENV KC_METRICS_ENABLED=true
ENV KC_HEALTH_ENABLED=true
ENV KC_FEATURES=preview,persistent-user-sessions
# ENV KC_HTTP_RELATIVE_PATH=/auth
ENV PROXY_ADDRESS_FORWARDING=true
ENV KC_BOOTSTRAP_ADMIN_USERNAME=admin
ENV KC_BOOTSTRAP_ADMIN_PASSWORD=password
ENV KC_DB=postgres
ENV KC_DB_URL_HOST=10.0.0.227
ENV KC_DB_URL_DATABASE=keycloak
ENV KC_DB_SCHEMA=public
ENV KC_DB_USERNAME=keyuser
ENV KC_DB_PASSWORD=keypass
ENV KC_HOSTNAME=keycloak.paykit.africa
ENV KC_HOSTNAME_STRICT=false
ENV KC_HTTP_ENABLED=true
ENV KC_HTTP_MANAGEMENT_PORT=9000
ENV KC_LOG_LEVEL=INFO
ENV KC_PROXY=edge
ENV KC_TRANSACTION_JTA_ENABLED=false
ENV KC_TRANSACTION_XA_ENABLED=false

ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start", "--optimized"]
# , "--optimized", "--hostname=localhost", "--db-pool-initial-size=10", "--db-pool-min-size=10", "--db-pool-max-size=30"