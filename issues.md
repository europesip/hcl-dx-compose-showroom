# Issues found with HCL DX Compose CF239 while preparing this showroom

Found while preparing the "Deploy HCL DX Compose in Minutes" webinar with DX Compose CF239 (`hcl-dx-deployment` 2.50.0,
`hcl-dx-iq` 1.0.3), what happens and how the files of this showroom deal with them. More issues found while building
the step-by-step labs are in [hcl-dx-compose-labs/issues.md](https://github.com/europesip/hcl-dx-compose-labs/blob/main/issues.md).

## SSL to the external database, LDAPS and LDAP sign-in (tested 2026-11-10)

Tested on a fresh installation (`hcl-dx-deployment` 2.50.0) with PostgreSQL 18 (CloudNativePG) that only accepts SSL
(`hostnossl all all all reject`) and an OpenLDAP that requires TLS, each server certificate signed by its own corporate
root CA, both CAs uploaded with `configuration.webEngine.customTruststoreSecrets`. Reported to HCL by e-mail (no case yet).

| # | What we tried | What happens (tested) | What this showroom does |
|---|---|---|---|
| S1 | `DbUrl` with two parameters: `?sslmode=verify-full&sslfactory=org.postgresql.ssl.DefaultJavaSSLFactory` | Works at runtime, but the **database transfer fails** on the first domain: `SAXParseException: Element type "database" must be followed by either attribute specifications, ">" or "/>"` in `templates/db/postgresql/release/dbt_release.xml`. The URL is written into that XML file without escaping `&`, so no second parameter can be used (client certificate, timeouts, `ApplicationName`...) | One parameter only: `?sslmode=verify-full` |
| S2 | `DbUrl` with `?sslfactory=org.postgresql.ssl.DefaultJavaSSLFactory` | The Web Engine never starts (CrashLoopBackOff): the tools that run before Liberty (`initStatusTable.sh`, `getLibertyStatus.sh`) use the default JDK truststore, not the CAs of `customTruststoreSecrets`: `PKIX path building failed`, then `Error extracting DB_TRANSFER_DONE status` | Not used |
| S3 | `DbUrl` with `?sslrootcert=<CA mounted from the truststore secret>` | Works (transfer of 465 tables, TLS 1.3) but the certificate is **not validated**: with the wrong CA it still connects (the driver stays on `sslmode=prefer`) | Not used |
| S4 | `DbUrl` with `?sslmode=verify-full` | **Works and validates**: transfer, pre-start tools and runtime over TLS 1.3. Without the database CA in `customTruststoreSecrets`: `PKIX path building failed`; with the service IP instead of the certificate host name: `The hostname … could not be verified by hostnameverifier PgjdbcHostnameVerifier` | The form used in the webinar |
| S5 | A database transfer that failed, then a corrected `helm upgrade` | The Web Engine pod never becomes ready and the StatefulSet does not replace it (`currentRevision ≠ updateRevision`) | Delete the pod by hand after fixing the values |
| S6 | IQ (`hcl-dx-iq` 1.0.3) with `configuration.database.dbTlsEnabled: true` | The value reaches the ConfigMap (`dx.config.integrator.db_tls_enabled: "true"`) but the Integrator still connects without SSL, and a server that requires SSL rejects it (`no encryption`) | `pg_hba` exception for the IQ database only (`host iqdb dx_iq_db_user all scram-sha-256`) |
| S7 | Sign in with the e-mail (`andres@europesip.com`) | The native LDAP block hard-codes `userFilter="(&(uid=%v)(objectclass=inetOrgPerson))"` (`_web-engine-ldap-config.tpl`) and no value changes it | `configOverrideFiles` extending `ldapRegistry id="ldap"` with `<loginProperty name="uid"/>` and `<loginProperty name="mail"/>` (the element form: the text form gives `CWWKG0075E`), plus a Web Engine restart |
| S8 | LDAPS (`port: 636`, `sslEnabled: true`) without the directory CA | `CWPKI0823E SSL HANDSHAKE FAILURE` / `PKIX path building failed`: nobody can sign in | The directory CA in `customTruststoreSecrets` |
| S9 | *Configuring LDAP* (configuration changes using overrides) | The AD SSL sample uses `sslRef="customSSLConfig"`, never defined on the page (it is generated when `customTruststoreSecrets` is set); e-mail login with `loginProperty` is not documented; both AD samples miss a closing parenthesis: `userFilter="(&(sAMAccountName=%v)(objectcategory=user)"` | Documentation feedback sent to HCL |

