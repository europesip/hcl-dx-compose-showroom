# HCL DX Compose showroom · Deploy HCL DX Compose in Minutes

**English** · [Español](index.es.md)

The files used in the **"Deploy HCL DX Compose in Minutes" webinar of 12 November 2026**: every values file, secret
layout and command that appears on screen, plus the presentation and the video of the session. They were generated
automatically by the [DX Installer Wizard](https://github.com/europesip/hcl-dx-compose-installer), an open-source tool
by EuropeSIP for HCL DX Compose (not an HCL product), with its webinar preset.

> This page is the summary for the developer portal. The full description is the
> [README on GitHub](https://github.com/europesip/hcl-dx-compose-showroom#readme), and the commands, step by step, are
> in the [RUNBOOK](https://github.com/europesip/hcl-dx-compose-showroom/blob/main/RUNBOOK.md).

> ⚠️ **Learning aid only.** This material does **not** replace the official HCL documentation, which remains the
> reference for installing, configuring and supporting HCL DX Compose:
> <https://help.hcl-software.com/digital-experience/dx-compose/CF239/>. Everything here is provided **AS IS**, without
> warranty of any kind (see the [LICENSE](https://github.com/europesip/hcl-dx-compose-showroom/blob/main/LICENSE)). It
> describes a basic example installation for a demonstration, not a production deployment.

**Frozen repository.** From 13 November 2026 the repository keeps the showroom exactly as it was presented and receives
no more changes. The [DX Installer Wizard](https://github.com/europesip/hcl-dx-compose-installer) keeps evolving: use it
for newer versions and other configurations.

## Who it is for

- Anyone who watched the webinar and wants to **run the showroom on their own environment**: the files are already
  prepared.
- Anyone who wants to see a **complete example** of what the DX Installer Wizard generates for a demo.

You do not need these files to install DX Compose: everything shown in the webinar can be done by following the official
HCL documentation.

## The presentation and the video

In [`media/`](https://github.com/europesip/hcl-dx-compose-showroom/tree/main/media):

- The [presentation (PDF)](https://github.com/europesip/hcl-dx-compose-showroom/blob/main/media/Deploy-HCL-DX-Compose-in-Minutes-slides.pdf)
  and the [transcript of the video](https://github.com/europesip/hcl-dx-compose-showroom/blob/main/media/video-transcript.txt).
- The full video (about 53 minutes, English narration, with subtitles) and **one video per lab**, as assets of the
  release [`webinar-2026-11-12`](https://github.com/europesip/hcl-dx-compose-showroom/releases/tag/webinar-2026-11-12):
  see [`media/README.md`](https://github.com/europesip/hcl-dx-compose-showroom/blob/main/media/README.md).

## How the webinar runs

The [RUNBOOK](https://github.com/europesip/hcl-dx-compose-showroom/blob/main/RUNBOOK.md) runs in two phases:

| Phase | Command | What it does |
|---|---|---|
| 1 · Preparation (before the session) | `./prepare.sh` | Corporate CAs and server certificates, OpenLDAP with the demo users, PostgreSQL 18 (CloudNativePG) |
| 2 · The demo (live) | `./demo.sh` | Stages 0 to 5, one command at a time (`--from <step>` to resume, `--no-pause`) |
| After the webinar | `./uninstall.sh` | Deletes everything that was installed |

| Stage | What it installs |
|---|---|
| 0 · Prerequisites | Checks, the `dx-demo` namespace, sign-in to the HCL Harbor (`hclcr.io`) and the charts |
| 1 · Base DX | Secrets (encrypted with SOPS), DX Compose, external access |
| 2 · LDAP | DX connected to OpenLDAP, administrator role, sign-in by e-mail, preferred language, LDAPS only |
| 3 · External database | Web Engine transferred from Derby to PostgreSQL over SSL |
| 4 · AI Assistant | LiteLLM and HCL DX IQ |
| 5 · Search | OpenSearch certificates, `hcl-dx-search`, Search V2 in DX |

Versions: DX Compose CF239, charts `hcl-dx-deployment` 2.50.0, `hcl-dx-iq` 1.0.3 and `hcl-dx-search` 2.37.0. You need
`kubectl` (with access to the cluster), `helm`, `openssl`, `curl` and `python3`; the RUNBOOK lists the resources the
installation asks for (look for about 11 CPU and 24 GiB free).

## Before you reuse the files

Adapt them to your installation:

- **Credentials.** Every password, token, key and password hash is replaced by `<REDACTED>`: put your own values.
- **SOPS-encrypted secrets.** `lab-base/secret-harbor.yaml` and `lab-base/secrets.yaml` are encrypted with SOPS and an
  age key that is ours: create your own key, put its public key in `.sops.yaml` and encrypt your values, or apply them
  as plain YAML.
- **Names.** Host names, namespaces (`dx-demo`, `dx-shared`), storage classes, the LDAP base DN and the demo users belong
  to our lab cluster.
- **Not included:** `setup-postgres-dx.sql` (HCL early-release material: ask HCL for it), the HCL charts and images
  (use your own HCL Harbor account) and keys and certificates (generated when the environment is prepared).

If you prefer not to edit the files by hand, or you need other options (OpenShift, Active Directory, Oracle, your own
registry, a secrets manager, Keycloak, AWS...), use the
[DX Installer Wizard](https://github.com/europesip/hcl-dx-compose-installer): it generates the same set of files for
your environment.

## What is in the repository

| Folder | Content |
|---|---|
| `lab-base/` | Namespaces, the base DX values, the Ingress and the DX secrets (encrypted with SOPS) |
| `lab-ldap/` | OpenLDAP values, the demo users, the basic and the complete LDAP layers, the XMLAccess request for the admin role and an Active Directory example (not applied) |
| `lab-bbdd/` | The PostgreSQL cluster (CloudNativePG, SSL only), its secrets and the Web Engine database properties |
| `lab-iq/` | LiteLLM and HCL DX IQ values |
| `lab-search/` | HCL DX Search (OpenSearch) values |
| `internals-ca/`, `prep-pki/` | The corporate CAs DX must trust, and the files used to sign the server certificates |
| `prepare.sh`, `demo.sh`, `RUNBOOK.md` | How the environment was prepared and the steps were run |
| `support/` | Support data: `environment-info.sh` and the HCL collector (`./demo.sh --collect`) |
| `media/` | The presentation, the transcript and the links to the videos |

Browse them on [GitHub](https://github.com/europesip/hcl-dx-compose-showroom).

## Known issues

[issues.md](https://github.com/europesip/hcl-dx-compose-showroom/blob/main/issues.md) lists the issues found with DX
Compose CF239 while preparing the showroom (SSL to the database, LDAPS, LDAP sign-in by e-mail) and how its files deal
with them.

## Related repositories

- [DX Installer Wizard](https://github.com/europesip/hcl-dx-compose-installer): generates these files, and a full proof
  of concept, for your own environment.
- [HCL DX Compose labs](https://github.com/europesip/hcl-dx-compose-labs): step-by-step labs with their guides.

Licence: [Apache License 2.0](https://github.com/europesip/hcl-dx-compose-showroom/blob/main/LICENSE). HCL charts and
images are not included.
