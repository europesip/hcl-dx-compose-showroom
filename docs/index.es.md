# Showroom de HCL DX Compose · Deploy HCL DX Compose in Minutes

[English](index.md) · **Español**

Los ficheros del **webinar «Deploy HCL DX Compose in Minutes» del 12 de noviembre de 2026**: cada fichero de valores,
la estructura de los secrets y cada comando que aparece en pantalla, además de la presentación y el vídeo de la sesión.
Se generaron automáticamente con el [DX Installer Wizard](https://github.com/europesip/hcl-dx-compose-installer), una
herramienta de código abierto de EuropeSIP para HCL DX Compose (no es un producto de HCL), con su configuración de
webinar.

> Esta página es el resumen para el portal del desarrollador. El repositorio está documentado en inglés: la descripción
> completa es el [README en GitHub](https://github.com/europesip/hcl-dx-compose-showroom#readme) y los comandos, paso a
> paso, están en el [RUNBOOK](https://github.com/europesip/hcl-dx-compose-showroom/blob/main/RUNBOOK.md).

> ⚠️ **Solo material de aprendizaje.** **No** sustituye a la documentación oficial de HCL, que sigue siendo la
> referencia para instalar, configurar y dar soporte a HCL DX Compose:
> <https://help.hcl-software.com/digital-experience/dx-compose/CF239/>. Todo se proporciona **TAL CUAL**, sin garantía
> de ningún tipo (ver la [LICENSE](https://github.com/europesip/hcl-dx-compose-showroom/blob/main/LICENSE)). Describe una
> instalación básica de ejemplo para una demostración, no un despliegue de producción.

**Repositorio congelado.** Desde el 13 de noviembre de 2026 conserva el showroom tal como se presentó y no recibe más
cambios. El [DX Installer Wizard](https://github.com/europesip/hcl-dx-compose-installer) sigue evolucionando: úsalo para
versiones más nuevas y otras configuraciones.

## Qué contiene

- **La presentación y el vídeo**, en [`media/`](https://github.com/europesip/hcl-dx-compose-showroom/tree/main/media):
  el [PDF](https://github.com/europesip/hcl-dx-compose-showroom/blob/main/media/Deploy-HCL-DX-Compose-in-Minutes-slides.pdf),
  la transcripción y, como recursos de la release
  [`webinar-2026-11-12`](https://github.com/europesip/hcl-dx-compose-showroom/releases/tag/webinar-2026-11-12), el vídeo
  completo (unos 53 minutos, narración en inglés) y un vídeo por lab.
- **Los ficheros de cada lab**: `lab-base/` (DX base, Ingress y secrets cifrados con SOPS), `lab-ldap/`, `lab-bbdd/`
  (PostgreSQL con SSL), `lab-iq/`, `lab-search/`, las CA corporativas (`internals-ca/`, `prep-pki/`) y `support/`.
- **Los scripts**: `prepare.sh` (fase 1, antes de la sesión: CA, OpenLDAP y PostgreSQL 18), `demo.sh` (fase 2, en
  directo: etapas 0 a 5, un comando cada vez) y `uninstall.sh`.

| Etapa | Qué instala |
|---|---|
| 0 · Prerrequisitos | Comprobaciones, el namespace `dx-demo`, acceso al Harbor de HCL (`hclcr.io`) y los charts |
| 1 · DX base | Secrets (cifrados con SOPS), DX Compose, acceso externo |
| 2 · LDAP | DX conectado a OpenLDAP, rol de administrador, inicio de sesión por e-mail, idioma preferido, solo LDAPS |
| 3 · Base de datos externa | Transferencia del Web Engine de Derby a PostgreSQL por SSL |
| 4 · Asistente de IA | LiteLLM y HCL DX IQ |
| 5 · Búsqueda | Certificados de OpenSearch, `hcl-dx-search`, Search V2 en DX |

Versiones: DX Compose CF239, charts `hcl-dx-deployment` 2.50.0, `hcl-dx-iq` 1.0.3 y `hcl-dx-search` 2.37.0.

## Antes de reutilizar los ficheros

No los necesitas para instalar DX Compose: todo lo del webinar se puede hacer con la documentación oficial de HCL. Si
los reutilizas, adáptalos: las credenciales están sustituidas por `<REDACTED>`, los dos secrets de `lab-base/` están
cifrados con SOPS y una clave age nuestra (crea la tuya o aplícalos como YAML en claro), y los nombres (hosts,
namespaces, storage classes, base DN, usuarios de demo) son los de nuestro clúster. No se incluyen
`setup-postgres-dx.sql` (material de acceso anticipado de HCL: pídeselo a HCL), los charts e imágenes de HCL ni las
claves y certificados. Para no editarlos a mano, o para otras opciones (OpenShift, Active Directory, Oracle, Keycloak,
AWS...), usa el [DX Installer Wizard](https://github.com/europesip/hcl-dx-compose-installer).

## Enlaces

- [Problemas encontrados](https://github.com/europesip/hcl-dx-compose-showroom/blob/main/issues.md) con DX Compose
  CF239 al preparar el showroom (SSL a la base de datos, LDAPS, inicio de sesión LDAP por e-mail), en inglés.
- [Labs de HCL DX Compose](https://github.com/europesip/hcl-dx-compose-labs): laboratorios paso a paso con sus guías.
- Código: [GitHub](https://github.com/europesip/hcl-dx-compose-showroom). Licencia:
  [Apache License 2.0](https://github.com/europesip/hcl-dx-compose-showroom/blob/main/LICENSE).
