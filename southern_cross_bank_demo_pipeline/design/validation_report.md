# Validation Report

## Checks Run During Generation

| Check | Result | Notes |
| --- | --- | --- |
| Skill preflight check | Pass with warnings | No existing `dbt_project.yml`, no Docusaurus project, no Mermaid config, and no local `dbt` command were detected. Static generation was safe. |
| DuckDB source context | Pass | `data/bank_demo.duckdb` exists and row-count checks succeeded for all nine `raw_bank` source tables. |
| DuckDB SQL function sanity | Pass | `AT TIME ZONE`, `bool_or`, `string_agg`, `date_diff`, `strftime`, `regexp_replace`, and `concat` were checked with the local DuckDB CLI. |
| YAML parse | Pass | All generated `.yml` files parse as YAML. |
| Output structure | Pass | Generated `models`, `docs`, `mappings`, `design`, `.github/workflows`, `.gitignore`, dbt project, profile, and tests. |
| Privacy scan | Pass with note | Mart SQL does not select direct names, email addresses, phone numbers, BSB, masked account number, or source case id. `date_of_birth` is referenced only to derive `age_band` and is not selected as a mart output column. |
| Bundled output validator | Warning | The validator flags legitimate dbt Jinja (`ref`, `source`, `config`) and GitHub Actions expressions as unresolved placeholders. These are required syntax, not unresolved template tokens. |
| Static docs workflow | Pass | GitHub Pages now publishes generated static docs from `site/` without running dbt. |

## DBT Validation Not Run Locally

`dbt` and `dbt-duckdb` were not installed in the local environment during generation, so `dbt parse`, `dbt compile`, and `dbt build` were not run.

Run these commands from the repository root after installing `dbt-duckdb`:

```bash
python -m pip install dbt-duckdb
dbt parse --project-dir southern_cross_bank_demo_pipeline --profiles-dir southern_cross_bank_demo_pipeline
dbt compile --project-dir southern_cross_bank_demo_pipeline --profiles-dir southern_cross_bank_demo_pipeline
dbt build --project-dir southern_cross_bank_demo_pipeline --profiles-dir southern_cross_bank_demo_pipeline
dbt docs generate --project-dir southern_cross_bank_demo_pipeline --profiles-dir southern_cross_bank_demo_pipeline
```

If the DuckDB file is not at `data/bank_demo.duckdb`, set `DUCKDB_PATH`:

```bash
DUCKDB_PATH=/path/to/bank_demo.duckdb dbt build --project-dir southern_cross_bank_demo_pipeline --profiles-dir southern_cross_bank_demo_pipeline
```

## Required Manual Review

The main validation assumption is that dbt Jinja and GitHub Actions expressions are valid syntax, not unresolved generation placeholders. Data quality coverage is implemented through schema tests, singular tests, source freshness documentation, and this follow-up dbt build checklist.

| Area | Review Item |
| --- | --- |
| Business date reproducibility | Decide whether `current_date` should be replaced by a supplied reporting date variable. |
| Pending card authorizations | Confirm whether pending card authorizations should remain in `fact_transactions` or move to a separate operational fact. |
| GitHub Pages | Enable GitHub Pages in the consuming repository settings and confirm the default branch is `main`. The included workflow publishes static docs without requiring `profiles.yml`. |
| Docusaurus MDX | If later moving the generated MDX page into Docusaurus, confirm the consuming Docusaurus site supports `@theme/Tabs`, `@theme/TabItem`, and Mermaid fences. |
