# Contributing to Prod Forge

Thank you for your interest in contributing.

This repository is the Terraform part of Prod Forge, an open-source guide to building and operating a production-ready backend on AWS. Contributions that improve the quality, clarity, and completeness of the infrastructure code and its documentation are welcome.

---

## What we are looking for

### Content contributions

- Corrections to technical inaccuracies
- Improvements to existing explanations
- New sections covering topics not yet addressed
- Real-world examples and case studies that illustrate a concept

### Code contributions

- Improvements to the Terraform modules and the `dev` and `prod` roots
- CI workflow improvements (`.github/workflows/terraform-ci.yml`)
- New `terraform test` coverage (`infrastructure/environments/prod/tests/`)
- Fixes to the commands and addresses in `docs/`

### Other contributions

- Typo and grammar fixes
- Broken link fixes
- Diagram improvements
- Translation (if you would like to maintain a translated version)

---

## What we are NOT looking for

- Suggestions to switch the core stack (Terraform, AWS, ECS Fargate) without strong justification
- Changes that make the project more like a boilerplate
- New features that increase complexity without educational value
- Opinionated changes that reflect personal preference rather than industry practice

When in doubt, open an issue before writing code.

---

## How to contribute

### 1. Open an issue first

For any non-trivial change, open an issue before submitting a pull request.

This allows us to discuss the proposed change and avoid wasted effort.

For small fixes (typos, broken links), you can submit a pull request directly.

### 2. Fork the repository

```shell
git clone https://github.com/prod-forge/terraform.git
cd terraform
```

### 3. Create a branch

Follow the branch naming convention used in the project:

```shell
feat/short-description
fix/short-description
docs/short-description
```

### 4. Make your changes

Keep changes focused. One pull request should address one thing.

Run the checks before opening a pull request (CI runs the same ones, none needs AWS credentials):

```shell
terraform fmt -check -recursive
terraform -chdir=infrastructure/environments/prod init -backend=false
terraform -chdir=infrastructure/environments/prod validate
terraform -chdir=infrastructure/environments/prod test
tflint --recursive
checkov -d infrastructure
```

Never run `terraform apply` against a shared account as part of a contribution, and never commit state files, keys or `.ovpn` files. A change to a module needs the matching update in `guide/` (and in the agent docs in `docs/` where they describe it) in the same pull request; see [CI for Infrastructure](guide/ci.md) for the full list of checks.

If you are adding a new section to the README or the docs, follow the existing writing style:

- short paragraphs
- plain language
- no unnecessary jargon
- concrete examples where possible
- explain the **why**, not just the **what**

### 5. Commit your changes

Follow the conventional commit format:

```text
docs(security): describe the CloudTrail bucket policy
fix(ci): correct workflow trigger condition
feat(alarms): add an RDS free storage alarm
```

### 6. Open a pull request

Include in the PR description:

- what the change does
- why it is needed
- any relevant context or references

---

## Writing style guide

This project has a specific tone. Please follow it when contributing content.

**Keep it simple.**
Write for a senior developer who is scanning quickly. Every sentence should earn its place.

**Explain the why.**
The value of this project is not in showing _what_ to do, but _why_ it matters. If you add a section, always include the reasoning.

**Use real examples.**
Abstract advice is easy to ignore. Concrete scenarios stick. When possible, illustrate a concept with a situation a developer would actually encounter.

**Be opinionated but honest.**
It is fine to take a position. But acknowledge trade-offs. Nothing in software engineering is universally correct.

**No buzzwords.**
Avoid phrases like "best-in-class", "battle-tested", "industry-leading". Write plainly.

---

## Code of conduct

Be respectful. Disagreements about technical approach are normal and healthy. Personal attacks are not. See the [Code of Conduct](https://github.com/prod-forge/.github/blob/main/CODE_OF_CONDUCT.md).

---

## Questions

If you are unsure about anything, open a GitHub Discussion or an issue.

We would rather answer a question than have someone spend time on a contribution that does not fit the project's direction.
