# HCL DX Compose showroom · the files of the "Deploy HCL DX Compose in Minutes" webinar

> [!IMPORTANT]
> **Disclaimer.** This material is provided **as a learning aid only**. It does **not** replace, and is not intended
> to replace in any way, the official HCL documentation, which remains the reference for installing, configuring and
> supporting HCL DX Compose: <https://help.hcl-software.com/digital-experience/dx-compose/CF239/>.
>
> Everything in this repository is provided **AS IS**, without warranty of any kind, express or implied (see
> [LICENSE](LICENSE)). The diagnostic tools in [`support/`](support/), and every script, runbook and file here
> (`prepare.sh`, `demo.sh`, `uninstall.sh`, `RUNBOOK.md`, the values files...), must be used **only as a practical
> learning reference**, never as a substitute for the official HCL material, documentation or support procedures.
> It describes a basic example installation for a demonstration, not a production deployment.

These are the files used in the **"Deploy HCL DX Compose in Minutes" webinar of 12 November 2026**: every values file,
secret layout and command that appears on screen.

They were **generated automatically by the [DX Installer Wizard](https://github.com/europesip/hcl-dx-compose-installer)**, an
open-source tool by EuropeSIP for HCL DX Compose (not an HCL product), with its webinar preset, the same tool that generates the material of a full proof of concept.

**If you want to run this showroom on your own environment, everything is here**: the files, already prepared, the
presentation and the video of the session.

> **Frozen repository.** From 13 November 2026 this repository is frozen: it keeps the showroom exactly as it was
> presented and receives no more changes. The [DX Installer Wizard](https://github.com/europesip/hcl-dx-compose-installer)
> keeps evolving: use it for newer versions and other configurations.

## The presentation and the video of the session

In [`media/`](media/):

- [`Deploy-HCL-DX-Compose-in-Minutes-slides.pdf`](media/Deploy-HCL-DX-Compose-in-Minutes-slides.pdf): the presentation.
- [`video-transcript.txt`](media/video-transcript.txt): the narration of the video, scene by scene.
- The full video and **one video per lab** (Lab 1 to Lab 5, to replay a single lab): see [`media/README.md`](media/README.md). It is published as an asset of a GitHub release of this
  repository, because it is larger than the file size GitHub accepts in a repository.

## Before you use these files

> **You do not need these files to install DX Compose.** Everything shown in the webinar can be done by following the
> official HCL documentation: <https://help.hcl-software.com/digital-experience/dx-compose/CF239/>.

If you want to reuse them, **adapt them to your installation**:

- **Credentials.** Every password, token, key and password hash is replaced by `<REDACTED>`: put your own values.
- **SOPS-encrypted secrets.** The two secrets of the base, `lab-base/secret-harbor.yaml` (the HCL Harbor pull secret)
  and `lab-base/secrets.yaml` (wpsadmin), are encrypted with [SOPS](https://github.com/getsops/sops) and an
  [age](https://github.com/FiloSottile/age) key, as shown in the webinar, and they too only hold `<REDACTED>`. You
  cannot decrypt them (the key is ours): create your own key with `age-keygen`, put its public key in `.sops.yaml`,
  write your values in plain YAML and encrypt the files with `sops -e -i <file>`. Or apply them as plain YAML: both
  ways give the same Secrets.
- **Names.** Host names (`*.apps.promox.europesip-lab.com`), namespaces (`dx-demo`, `dx-shared`), storage classes,
  the LDAP base DN and the demo users belong to our lab cluster.
- **Not included:** `setup-postgres-dx.sql` (the PostgreSQL table script is HCL early-release material: ask HCL for
  it), the HCL charts and images (use your own HCL Harbor account, hclcr.io), and keys and certificates (they are
  generated when the environment is prepared).

**If you prefer not to edit the files by hand**, or you need other configuration options (OpenShift, Active Directory,
Oracle, your own image registry, a secrets manager, Keycloak, AWS...), use the
**[DX Installer Wizard](https://github.com/europesip/hcl-dx-compose-installer)**: it asks for your values and
generates the same set of files, already filled in for your environment.

## What is here

| Folder | Content |
|---|---|
| `lab-base/` | Namespaces, the base DX values (`custom-values.yaml`), the Ingress and the DX secrets, encrypted with SOPS (`secret-harbor.yaml`, `secrets.yaml`; rules in `/.sops.yaml`) |
| `lab-ldap/` | OpenLDAP values, the demo users (`demo-users.ldif`), the bind secret, the **basic** LDAP layer (`custom-values.ldap-basic.yaml`) and the **complete** one with configuration overrides (`custom-values.ldap.yaml`: sign in by e-mail, preferred language, LDAPS with the corporate CAs), the XMLAccess request for the admin role and an **example** for a corporate Active Directory (`example-active-directory.yaml`, not applied) |
| `lab-bbdd/` | The PostgreSQL cluster (CloudNativePG, SSL only), its secrets and the Web Engine database properties (`dx_dbdomain.properties`, JDBC over SSL with `sslmode=verify-full`) |
| `lab-iq/` | LiteLLM and HCL DX IQ values |
| `lab-search/` | HCL DX Search (OpenSearch) values |
| `internals-ca/` | Explains the corporate CAs (directory and databases) that DX must trust. The certificates themselves are created when the environment is prepared |
| `prep-pki/` | The `openssl` extension files used to sign the server certificates during the preparation |
| `prepare.sh`, `demo.sh`, `RUNBOOK.md` | How we prepared the environment before the session and ran its steps |
| `media/` | The presentation (PDF), the transcript of the video and the link to the video |
| [`issues.md`](issues.md) | Issues found with DX Compose CF239 while preparing this showroom (SSL to the database, LDAPS, LDAP sign-in), and how they are handled |

## Related repositories

- [DX Installer Wizard](https://github.com/europesip/hcl-dx-compose-installer): generates these files, and a full
  proof of concept, for your own environment. It keeps evolving.
- [HCL DX Compose labs](https://github.com/europesip/hcl-dx-compose-labs): step-by-step labs with their guides.
