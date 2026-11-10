# internals-ca · the CAs of corporate IT

The certificates of the root CAs that sign the servers of the corporate infrastructure DX connects to:

- `corporate-directory-ca.crt` · **EUROPESIP Corporate Directory Root CA**: the corporate directory (OpenLDAP, LDAPS on port 636).
- `corporate-database-ca.crt` · **EUROPESIP Corporate Database Root CA**: the corporate databases (PostgreSQL, SSL only).

DX must trust them: `customTruststoreSecrets` uploads them to the truststore of Liberty from the secret
`dx-corporate-cas` (one file per CA). Without them, LDAPS and SSL to the database fail with "PKIX path building failed".

In a real project corporate IT gives you these files. In this lab the preparation creates them (`prep-pki/` plays the
part of corporate IT: the CA keys and the server certificates). The other CAs of the lab, such as the one of OpenSearch
(lab-search/certs), we generate ourselves.
