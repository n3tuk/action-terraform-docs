# n3tuk Terraform Documentation Action

[![GitHub script-integrations Workflow Status](https://img.shields.io/github/actions/workflow/status/n3tuk/action-terraform-docs/script-integrations.yaml?label=script-integrations&style=flat-square)](https://github.com/n3tuk/action-terraform-docs/actions/workflows/script-integrations.yaml)

A GitHub Action for running [`terraform-docs`][terraform-docs] against a
repository to automatically update the `README.md` file in a configuration with
standard documentation covering items such as variables, outputs, and resources.

[terraform-docs]: https://github.com/terraform-docs/terraform-docs

```yaml
---
name: terraform-docs

on:
  pull_requests:
    branches:
      - main
      - master

permissions:
  contents: write
  packages: read
  issues: read
  pull-requests: write

jobs:
  terraform-docs:
    name: Run terraform-docs
    runs-on: ubuntu-latest
    steps:
      - name: Checkout the repository
        uses: actions/checkout@v3
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          # Ensure the upstream reference is checked out in case we need to push
          # documentation changes back to the branch on the repository
          ref: ${{ github.event.pull_request.head.ref }}

      - name: Run terraform-docs
        uses: n3tuk/action-terraform-docs@v1
        with:
          working-directory: |-
            terraform
            modules
          config-file: .terraform-docs.yaml
          recursive: "true"
          git-push: "true"
```

## Using `GITHUB_TOKEN`

Note that this GitHub Action does not use `GITHUB_TOKEN` directly. It will not
create a pull request on changes, or make direct requests against GitHub. If
there are changes it will either fail, or stage and commit directly via `git`
and push back to the `origin`.

As such `git` will use the credentials provided when checking out the repository
through the `when.token` argument, shown above.

By default this action uses the automatically generated `GITHUB_TOKEN` which
allows it to push changes (assuming `permissions.contents` is set to `write`)
back to the pull request, and uses the account of GitHub Actions to provide the
`git-name` and `git-email` values for the configuration of `git`.

If you change `GITHUB_TOKEN` to be a specific bot or user account, it's
recommended to update `git-name` and `git-email` to reflect the details of that
account.

## Configuration Files

The configuration files for `terraform-docs`, when committed to the repository
and configured in the GitHub Action, can be set one of three levels:

1. The directory of a Terraform configuration, which will be used for that
   configuration only;
1. The `working-directory` being processed, which will be used as the default
   configuration used for all Terraform configurations found under that
   `working-directory`; and
1. The `root` of the repository, which will be in effect the default
   configuration file used for all Terraform configurations if no other file is
   found.

Assuming the structure of the Terraform repository is as follows:

```sh
terraform-configuration/
├── terraform/
│   ├── main.tf
│   ├── terraform.tf
├── modules/
│   ├── module-one/
│   │   ├── main.tf
│   │   ├── terraform.tf
│   ├── module-two/
│   │   ├── module-three/
│   │   │   ├── main.tf
│   │   │   └── terraform.tf
│   │   ├── main.tf
│   │   ├── terraform.tf
│   │   └── .terraform-docs.yaml
│   └── .terraform-docs.yaml
├── README.md
└── .terraform-docs.yaml
```

And the GitHub Action is configured to recursively scan the `terraform/` and
`modules/` directories, looking for any with `.tf` files within, and the
`config-file` set to look for the file `.terraform-docs.yaml`, as follows:

```yaml
- name: Run terraform-docs
  uses: n3tuk/action-terraform-docs@v1
  with:
    working-directory: |-
      terraform
      modules
    config-file: .terraform-docs.yaml
    recursive: true
```

The following four Terraform configurations will be found, and will use the
noted configuration file:

1. `modules/module-two/module-three` will use `modules/.terraform-docs.yaml`
   (The file `modules/module-two/.terraform-docs.yaml` in the parent directory
   will not be used for this module as that is specific to `module-two`, so the
   fallback is to `modules/.terraform-docs.yaml`);
1. `modules/module-two` will use `modules/module-two/.terraform-docs.yaml`
   (specific override for this module);
1. `modules/module-one` will use `modules/.terraform-docs.yaml` (use the
   default for the `working-directory`); and
1. `terraform` will use `.terraform-docs.yaml` in the `root` of the repository
   (no local override, or `working-directory` override - they are the same
   directory in effect - so use the repository default).

> **Note**
> Any search for configurations and modules explicitly excludes any directories
> under `.terraform/modules` which are sourced by `terraform init` and `get`,
> and `.external_modules` which are sourced by `checkov`. These are only
> temporary downloads and shouldn't normally be part of standard documentation.

### Recursion

Although this GitHub Action supports the `recursive` input which can switch on
or off recursively processing Terraform configurations under a selected
directory, it does **not** use the `--recursive` and `--recursive-path` options
for `terraform-docs`.

`terraform-docs` only supports a single directory to run a recursive scan under,
using the `--recursive-path` command line argument, and that path cannot be the
same as the current working directory. This may not be ideal when you have
multiple sub-directories to scan (e.g. `modules/` and `examples/` directories
within the repository).

Therefore this GitHub Action performs a custom recursive scan of each
`working-directory` configured for the Action, including `.` (i.e. the root of
the repository) if that is the only directory configured.

None of this overrides the `recursive` configuration in the `.terraform-docs.yaml`
file; `recursive.enabled` and the `recursive.path` can be set regardless of if
`recursive` is set for this Action. Just be careful if this Action or the
`terraform-docs` attempts to duplicate each other's work (and they have
different settings).

## Output Configurations

TODO

<!-- BEGIN_ACTION_DOCS -->

## Action Inputs

| Input               | Description                                                                                                                                                                                                                                                         | Required | Default                                                                |
| :------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | :------: | :--------------------------------------------------------------------- |
| `working-directory` | A list of one or more working directories that `terraform-docs` should be run within, with each directory on a new line when required. Use `.` for the root directory of the repository.                                                                            |  `true`  |                                                                        |
| `config`            | The configuration file for `terraform-docs` which will be given when it is run within each of the working directories. If the file resides in the directory being run, that has priority, followed by the working directory, and then the `root` of the repository. | `false`  |                                                                        |
| `recursive`         | Recursively scan each of the `working-directory` entries for directories with `.tf` files for processing by `terraform-docs`.                                                                                                                                       | `false`  | `false`                                                                |
| `output-format`     | The output type to generate the content from `terraform-docs` (e.g. `markdown table`). This is ignored if `config-file` is set.                                                                                                                                     | `false`  | `markdown table`                                                       |
| `output-mode`       | One of the three `replace`, `inject`, or `print` modes for handling the generated content. This is ignored if `config-file` is set.                                                                                                                                 | `false`  | `inject`                                                               |
| `indent`            | When using one of the `markdown` formats, set how deep the header indentation is for the generated content. This is ingored if `config-file` is set.                                                                                                                | `false`  | `2`                                                                    |
| `output-template`   | The template to use when generating content before being processed by the selected `output-mode` into the `output-file`. Can be useful for adding comments when using `inject`. This is ignored if `config-file` is set.                                            | `false`  | `<!-- BEGIN_TF_DOCS --><br />{{ .Content }}<br /><!-- END_TF_DOCS -->` |
| `output-file`       | This is the name of the file to work with based on the `output-mode` configured, and to which the generated content will be handled. This is ignored if `config-file` is set.                                                                                       | `false`  | `README.md`                                                            |
| `lockfile`          | Read the `.terraform.lock.hcl` file in the configuration, if present, for the versions of the Terraform providers used in this configuration. This is ignored if `config-file` is set.                                                                              | `false`  | `true`                                                                 |
| `fail-on-diff`      | Set whether or not to fail the GitHub Action is any changes are detected in the repository after `terraform-docs` has been run.                                                                                                                                     | `false`  | `false`                                                                |
| `show-on-diff`      | Set whether or not to show any changes detected in the repository after `terraform-docs` has been run.                                                                                                                                                              | `false`  | `true`                                                                 |
| `git-push`          | Set whether or not to stage, commit, and push any changes made in the repository after running `terraform-docs` back to the branch.                                                                                                                                 | `false`  | `false`                                                                |
| `git-name`          | Set the name of the comitter for git if changes are staged and comitted. This is ignored unless `git-push` is set.                                                                                                                                                  | `false`  | `github-actions[bot]`                                                  |
| `git-email`         | Set the email of the comitter for git if changes are staged and comitted. This is ignored unless `git-push` is set.                                                                                                                                                 | `false`  | `41898282+github-actions[bot]@users.noreply.github.com`                |
| `git-title`         | Set the title of the commit message (i.e. the first line) if any changes are staged and commited back to the repository after `terraform-docs` has been run. This is ignored unless `git-push` is set.                                                              | `false`  | ``Syncing changes made by `terraform-docs```                           |
| `git-body`          | Set the body of the commit message (if required) if any changes are staged and commited back to the repository after `terraform-docs` has been run. This is ignored unless `git-push` is set.                                                                       | `false`  |                                                                        |

<!-- END_ACTION_DOCS -->
