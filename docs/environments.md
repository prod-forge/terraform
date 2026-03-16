# Environments

<p align="center">
  <img alt="Environments" src="https://github.com/prod-forge/terraform/blob/main/assets/environments.png" width="512px" height="550px">
</p>

Many projects introduce multiple environments such as:

- development
- staging
- pre-production
- production

While this may seem beneficial, in practice maintaining too many environments often increases operational complexity.

Each additional environment introduces:

- configuration drift
- infrastructure overhead
- additional maintenance
- inconsistent behavior between environments

Because of this, the approach used in this project is intentionally simple.

## Environment Strategy

The system operates with two primary environments:

- dev
- prod

The key principle is that these environments should be as similar as possible.

Infrastructure, configuration patterns, and deployment processes should mirror each other closely. This reduces the risk
of unexpected issues appearing only after deployment to production.

### Development Environment (dev)

The dev environment is used for:

- active development
- experimentation and prototyping
- integration testing
- validating infrastructure changes

Developers can safely iterate and test new functionality here without affecting live users.

### Production Environment (prod)

The prod environment represents the live system.

It serves real users and therefore must prioritize:

- stability
- reliability
- observability
- safe deployment practices

All production deployments are executed through the automated CI/CD pipeline.

### Why Not Use Pre-Production?

Some teams introduce an additional pre-production or staging environment before production.

The goal is usually to perform a final verification before deploying to production.

However, this approach can sometimes create a false sense of safety and increase operational overhead.

Instead, this project follows a different philosophy:

> Production deployments should be frequent, small, and predictable.

When releases happen regularly and the deployment process is fully automated, deploying to production becomes a routine
operation rather than a risky event.

Smaller and more frequent releases reduce risk and allow issues to be detected and resolved faster.

## Key Principle

The most important rule is:

**Environments should behave the same way.**

If development and production environments are consistent in terms of infrastructure and configuration, the likelihood
of unexpected production issues is significantly reduced.
