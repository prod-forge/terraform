# No CD workflows deploy dev

- **What:** Terraform creates the dev deploy roles (`<project>-dev-github-backend-role`, `<project>-dev-github-frontend-role`), which trust only the `environment:dev` subject, but every backend and frontend deploy workflow hard-codes `environment: prod`. CD deploys prod only; dev runs the `initial` image until it is deployed by hand.
- **Where:** `infrastructure/modules/github-oidc/main.tf`, `infrastructure/modules/stack/main.tf` (dev role trust); in the backend repository `.github/workflows/cd.yml`, `rollback.yml`, `show-ecs-revisions.yml`; in the frontend repository `.github/workflows/cd.yml`, `rollback.yml`, `show-web-client-versions.yml`. Step 7 of "Creating dev" in `guide/environments.md`.
- **Why deferred:** dev CD is not built; the owner decided on 2026-11-05 to document the gap instead.
- **What a fix needs:** parametrise the workflows by GitHub environment (an input or a branch/tag rule that picks `dev` or `prod`), create the `dev` GitHub environment with its own variables filled from `terraform -chdir=infrastructure/environments/dev output`, and then update `guide/environments.md` and `guide/workflow.md` ("Deploy workflow variables").
