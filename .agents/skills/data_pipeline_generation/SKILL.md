---
name: data-pipeline-generation
description: Generate DBT pipeline artifacts from a source table, business requirements, and lake or semantic context. Use when asked to create analytics engineering deliverables including DBT SQL/YAML models, data definitions, source-to-target mappings, lineage notes, pipeline design documents, SQL dialect-aware transformations, output-package gitignore files, validation checklists, GitHub Actions workflows for publishing Docusaurus to GitHub Pages, or a Docusaurus MDX documentation page delivered with the generated SQL files.
---

# DBT Pipeline Generation

Use this skill to turn a source table plus business requirements into a reviewable DBT pipeline output package. Generate SQL-first DBT artifacts and documentation that a data engineer, analytics engineer, business analyst, and governance reviewer can inspect before execution.

## Preflight Dependency Gate

Before generating files in a target repository, check the dependencies needed for the requested output. Exit early only when a missing dependency makes the requested output impossible to generate safely.

DBT artifact generation assumes a fresh pipeline by default:

- Do not block generation when `dbt_project.yml` is absent.
- If no DBT project exists, generate a fresh pipeline package and include `assets/dbt/dbt-project.yml` when a project scaffold is needed.
- Use existing `dbt_project.yml`, adapter packages, or model conventions only when they are present.
- The target SQL dialect is still required or must be inferable before dialect-specific SQL is generated.

Required when generating or validating a Docusaurus MDX page:

- `package.json`.
- Docusaurus dependency such as `@docusaurus/core`.
- TypeScript support when the Docusaurus repository uses TypeScript, such as `typescript`, `tsconfig.json`, or `.tsx` config/components.
- Docusaurus theme tabs support through `@theme/Tabs` and `@theme/TabItem`.
- Mermaid rendering support in Docusaurus, such as `@docusaurus/theme-mermaid` and `markdown.mermaid: true`, or confirmation that the consuming repository already renders Mermaid fences.

Required when generating a GitHub Actions publishing workflow:

- Confirmation that the consuming repository will publish with GitHub Pages.
- Docusaurus build command, usually `npm run build`.
- Package manager lockfile or explicit package manager choice.
- Docusaurus build output directory, usually `build/`.

Required when running command validation:

- `dbt` for `dbt parse` or `dbt compile`.
- Node package manager files such as `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, or `bun.lockb` for reproducible Docusaurus installs.
- Installed dependencies, usually `node_modules/`, or permission to install them.

If a true required dependency is missing, stop before creating or modifying output files and report:

- Missing dependency.
- Why it is required.
- Affected output.
- Suggested fix.
- Whether static-only generation remains possible.

Use this report shape:

```markdown
## Dependency Check Failed

| Dependency | Required For | Status | Suggested Fix |
| --- | --- | --- | --- |
| typescript | Docusaurus TypeScript build | Missing | Add `typescript` and `tsconfig.json`, or confirm the docs site is JavaScript-only. |

No files were generated. Static-only generation can continue if you confirm the missing dependency is not required for this repository.
```

## Inputs To Look For

Identify or request these inputs:

- Source table: database, schema, table name, columns, data types, grain, freshness, constraints, sample values, and known quality issues.
- Business requirements: target entity, measures, dimensions, filters, business rules, reporting needs, acceptance criteria, and edge cases.
- Lake or semantic context: upstream zones, domain terms, semantic maps, glossary definitions, related models, and lineage hints.
- Target context: warehouse dialect, DBT model naming, materialization, ownership, scheduling, environments, and schema conventions.

If a required detail is missing, proceed with explicit assumptions when safe. Ask concise clarification questions only when the missing detail would materially change SQL logic, grain, joins, or target semantics.

## Workflow

1. Run the preflight dependency gate for the requested outputs.
2. Establish source grain and target grain.
3. Extract business entities, metrics, dimensions, and required filters from the requirements.
4. Map semantic terms to source columns and note any gaps.
5. Determine the required SQL dialect before writing SQL.
6. Design the DBT model shape: staging, intermediate, and mart/final models.
7. Generate SQL using the confirmed or inferred target warehouse dialect.
8. Generate YAML for sources, models, column descriptions, and tests supported by the requirements.
9. Produce source-to-target mappings for final output columns.
10. Produce a design document explaining the model structure, transformation flow, assumptions, and test strategy.
11. Produce one Docusaurus MDX page for the same pipeline context. Deliver it with the SQL files, not inside this skill repository.
12. Create a relevant `.gitignore` for the output package.
13. Create or update a GitHub Actions workflow for publishing the Docusaurus site to GitHub Pages when requested or when the consuming repository needs it.
14. Run or document validation before handing off the package.

## Output Package

Prefer this output shape unless the user or repository conventions require another layout:

```text
<pipeline-context>/
  .gitignore
  .github/
    workflows/
      publish-docusaurus.yml
  models/
    staging/
      stg_<source>.sql
    intermediate/
      int_<business_process>.sql
    marts/
      <target_model>.sql
    schema.yml
    sources.yml
  docs/
    <pipeline-context>.mdx
  mappings/
    source_to_target.md
  design/
    design_document.md
```

The generated Docusaurus page travels with the generated SQL files. The consuming pipeline repository decides where to commit the package and how to wire the MDX page and workflow into Docusaurus and GitHub Pages.

## Bundled Assets

Use bundled assets when generating outputs:

- `assets/dbt/staging-model.sql`: staging model SQL template for source normalization and renaming.
- `assets/dbt/intermediate-model.sql`: intermediate model SQL template for joins, business rules, reusable logic, and aggregations.
- `assets/dbt/mart-model.sql`: mart/final model SQL template for the business-facing output dataset.
- `assets/dbt/sources.yml`: DBT source YAML template.
- `assets/dbt/schema.yml`: DBT model schema YAML template.
- `assets/dbt/model-column.yml`: reusable model column YAML snippet.
- `assets/dbt/source-column.yml`: reusable source column YAML snippet.
- `assets/dbt/dbt-project.yml`: lightweight DBT project scaffold template, used when generating a fresh standalone DBT pipeline package.
- `assets/docusaurus/pipeline-page.mdx`: full MDX page template with tabs for overview, DBT pipeline, data definition, mappings, design, Mermaid diagrams, assumptions, open questions, and validation.
- `assets/docusaurus/pipeline-page-minimal.mdx`: smaller MDX page template for simpler contexts.
- `assets/docusaurus/sidebar-item.js`: sidebar item snippet for wiring the generated page into a consuming Docusaurus site.
- `assets/github-actions/publish-docusaurus.yml`: GitHub Actions workflow template for publishing the consuming Docusaurus site to GitHub Pages.

Replace `{{placeholder}}` values with generated content. Do not leave unresolved placeholders in final deliverables.

## Bundled Scripts

- Use `scripts/preflight_check.py <repo-path>/` before generating files in a consuming repository. It reports DBT context, package manager, Docusaurus, TypeScript, Mermaid, SQL dialect, GitHub Pages workflow, and local `dbt` command readiness.
- Use `scripts/render_template.py` to render bundled assets that contain `{{placeholder}}` tokens. It accepts repeated `--var key=value` values and JSON files through `--vars-json`.
- Use `scripts/validate_output_package.py <pipeline-context>/` after generating an output package. It performs static checks for required folders, unresolved placeholders, DBT SQL/YAML, Docusaurus MDX tabs, Mermaid fences, source-to-target mappings, design docs, `.gitignore`, and GitHub Pages workflows. Use `--strict` when warnings should fail validation.

## SQL Dialect Handling

Identify the target SQL dialect before generating model SQL. Prefer explicit user or repository context over inference.

Supported first-pass dialect targets:

- Snowflake.
- BigQuery.
- Databricks SQL or Spark SQL.
- Redshift.
- Postgres.

If the dialect is not supplied:

- Inspect repository context for `dbt_project.yml`, adapter packages, profiles examples, existing SQL syntax, or naming conventions.
- Infer only when evidence is strong, and state the evidence.
- Ask one concise clarification question when dialect differences affect generated logic, such as date functions, casting, arrays, structs, `QUALIFY`, identifier quoting, or incremental strategies.
- If no answer is available, generate conservative ANSI-style SQL and list the dialect as an open question.

Record the selected dialect in the design document and the Docusaurus overview tab.

## DBT SQL And YAML Rules

- Keep transformations readable and reviewable.
- Use `assets/dbt/staging-model.sql` for source normalization, naming, type casting, and light cleanup.
- Use `assets/dbt/intermediate-model.sql` for joins, business-rule application, aggregations, or reusable logic.
- Use `assets/dbt/mart-model.sql` for the requested business-facing dataset.
- Use `assets/dbt/sources.yml` and `assets/dbt/schema.yml` for DBT YAML outputs.
- Include DBT tests only when supported by requirements or source metadata, such as `not_null`, `unique`, `relationships`, `accepted_values`, or freshness expectations.
- Do not silently invent business rules. Mark assumptions clearly.
- Prefer stable model names: `stg_<source>`, `int_<process>`, and `<business_entity_or_metric>`.
- Use `assets/dbt/dbt-project.yml` when no existing DBT project is present and the output should be a fresh standalone pipeline package.

## Output Package Gitignore

Create a `.gitignore` at the root of the generated output package unless the consuming repository already has an equivalent ignore policy. Include entries relevant to DBT, local Python environments, editor state, logs, and generated site builds.

Use this baseline:

```gitignore
target/
dbt_packages/
logs/
.user.yml
.env
.env.*
!.env.example
.venv/
venv/
__pycache__/
*.py[cod]
.DS_Store
.idea/
.vscode/
node_modules/
build/
.docusaurus/
```

Do not ignore generated SQL, YAML, Markdown, MDX, mappings, or design documents.

## Data Definition

Document the dataset purpose, business grain, entities represented, column definitions, data types, semantic meaning, metric logic, dimension logic, caveats, assumptions, and exclusions. Write this for both business and technical reviewers.

## Source-To-Target Mapping

Create a mapping table with:

- Target model.
- Target column.
- Source table.
- Source column.
- Transformation logic.
- Business rule reference.
- Data quality expectation.
- Notes for joins, filters, defaults, derivations, or aggregations.

Use Markdown table format by default. Add CSV or JSON only when requested.

## Design Document

Include:

- Problem statement and business objective.
- Source and target summary.
- Proposed DBT model structure.
- Transformation flow.
- Mermaid pipeline flow and source-to-target lineage diagrams.
- Mermaid model dependency diagram when the pipeline has more than one generated model.
- Key business rules.
- Data quality and testing strategy.
- Assumptions, risks, and open questions.
- Operational notes such as ownership, freshness, scheduling, and failure handling.

## Docusaurus MDX Page

Create one MDX page per pipeline context. Organize related content under tabs so the SQL, definitions, mappings, design, diagrams, and assumptions remain together.

Start from `assets/docusaurus/pipeline-page.mdx` unless the context is small enough for `assets/docusaurus/pipeline-page-minimal.mdx`.

Use this tab structure by default:

- Overview.
- DBT pipeline.
- Data definition.
- Source-to-target mappings.
- Design document.
- Mermaid diagrams.
- Assumptions and open questions.

Use Docusaurus `Tabs` and `TabItem` imports when producing an actual MDX file:

```mdx
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';
```

The page must be ready for the consuming pipeline repository to expose through its sidebar, navbar, or responsive hamburger menu.

Every generated MDX page must include Mermaid diagrams. At minimum, generate:

- Pipeline flow: source, staging, intermediate, mart/final model, and documentation output.
- Source-to-target lineage: source columns or source entities to target model columns or metrics.

Also generate a model dependency diagram when the pipeline has multiple DBT models. Keep diagrams concise enough to render legibly in Docusaurus.

## GitHub Actions Docusaurus Publishing

When requested, or when the consuming pipeline repository does not already have a publishing workflow, generate a workflow file for GitHub Pages. Prefer `.github/workflows/publish-docusaurus.yml` in the consuming repository.

Start from `assets/github-actions/publish-docusaurus.yml` and replace all placeholders using the consuming repository's conventions.

Before writing a workflow:

- Check for existing workflows under `.github/workflows/`.
- Preserve existing deployment conventions if present.
- Use the package manager implied by the lockfile: `npm`, `yarn`, `pnpm`, or `bun`.
- Use the repository's actual Docusaurus build command and output directory.
- Include `permissions` for `contents: read`, `pages: write`, and `id-token: write`.
- Configure concurrency so only one Pages deployment runs at a time.

Default placeholder values when no stronger repository convention exists: `{{default_branch}}` = `main`, `{{docs_path}}` = `docs`, `{{workflow_filename}}` = `publish-docusaurus.yml`, `{{node_version}}` = `20`, `{{package_manager}}` = `npm`, `{{lockfile_path}}` = `package-lock.json`, `{{install_command}}` = `npm ci`, `{{build_command}}` = `npm run build`, and `{{build_output_path}}` = `build`.

If the output package is not located at the consuming repository root, provide the workflow as a deliverable and clearly state where it should be copied.

## Validation

Perform validation when files are generated in a repository. If tools are unavailable, produce a validation checklist with pass/fail notes and commands the user can run.

Minimum validation:

- Confirm every target output column appears in the source-to-target mapping.
- Confirm every mapped source column exists in the supplied source metadata or is marked as an assumption.
- Confirm the selected SQL dialect is recorded and dialect-specific syntax is intentional.
- Confirm DBT `ref()` and `source()` references match generated model and source names.
- Confirm YAML model columns match SQL select aliases.
- Confirm generated tests are supported by requirements or metadata.
- Confirm the MDX page imports `Tabs` and `TabItem` when tabs are used.
- Confirm Mermaid diagrams are present in the generated MDX documentation.
- Confirm Mermaid diagrams are fenced as `mermaid`.
- Confirm the consuming Docusaurus project supports Mermaid rendering or list the required config change.
- Confirm `.gitignore` exists in the output package and does not hide generated deliverables.
- Confirm the GitHub Actions workflow uses the correct package manager, build command, build output path, Pages permissions, and deployment actions.

Preferred command validation when applicable:

```bash
python3 path/to/data_pipeline_generation/scripts/preflight_check.py <consuming-repo>/
python3 path/to/data_pipeline_generation/scripts/render_template.py assets/dbt/staging-model.sql --list-placeholders
python3 path/to/data_pipeline_generation/scripts/validate_output_package.py <pipeline-context>/
dbt parse
dbt compile
npm run build
```

Only claim command validation passed if it was actually run. Otherwise, state that validation is static review only.

## Quality Bar

- Separate confirmed facts from assumptions.
- Preserve lineage from source fields to target fields.
- Keep generated SQL and documentation deterministic enough for golden-output tests.
- Prefer concise comments only where transformation logic is not self-evident.
- Flag unresolved decisions, especially warehouse dialect, grain, joins, metric definitions, and semantic-map gaps.
