# Security Policy

## Supported version

Security fixes are applied to the latest release on `main`.

## Reporting a vulnerability

Please use GitHub's private vulnerability reporting for this repository. Include the affected component, reproduction steps, impact, and any suggested mitigation. Avoid opening a public issue until a fix is available.

## Operational guidance

- Treat `.env.example` values as local development defaults only.
- Supply unique secrets through environment variables outside development.
- Bind database ports to trusted interfaces and restrict network access.
- Use a least-privileged database account for applications.
- Do not load real personal or competition data into the demonstration environment.
