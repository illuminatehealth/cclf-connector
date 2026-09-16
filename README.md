[![Apache License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) ![dbt logo and version](https://img.shields.io/static/v1?logo=dbt&label=dbt-version&message=1.x&color=orange)

# Medicare CCLF Connector

## 🔗 Docs
Check out our [docs](https://thetuvaproject.com/) to learn about the project and how you can use it.
<br/><br/>

## 🩹 What is patched in this fork?

This is Illuminate Health's maintained fork of the Tuva Medicare CCLF Connector.
It runs in production for Medicare Shared Savings Program ACOs on Microsoft
Fabric. It carries changes to the related-claims adjustment logic, support for
weekly CCLF releases, and eligibility built directly from ALR files, none of
which are in the upstream connector yet. Everything else follows Tuva.

### Related-claims adjustment logic

CMS describes related claims in the [CCLF Information Packet](https://www.cms.gov/files/document/cclf-information-packet.pdf)
(Version 43, May 13, 2026). Section 5.1.2, "Natural Keys", on page 15 defines
the key that groups every version of a claim: for Part A it is
`CLM_BLG_PRVDR_OSCAR_NUM`, `CLM_FROM_DT`, `CLM_THRU_DT` and the most recent MBI;
for Part B physician and DME it is `CLM_CNTL_NUM` and the most recent MBI. The
connector adds `CLM_LINE_NUM` to the Part B key so that line detail survives.
Section 5.2 on pages 17 and 18 lists the combinations a related set can
contain, including "two original claims (and no other related claims)", and
notes that "it is possible that there is more than one final action claim among
a related set of claims." Section 5.3.1 on page 19 gives the expenditure
method: flip the sign of every cancellation (`CLM_ADJSMT_TYPE_CD = 1`) and sum.

The models involved are `int_physician_claim_adr`, `int_dme_claim_adr` and
`int_institutional_claim_adr`, plus the matching `*_claim_deduped` models. This
fork changes three things about how they resolve a related set.

**Duplicate deliveries are removed by claim identity.** CMS delivers the same
claim more than once across monthly files, and later file layouts leave columns
such as the HIC number and BETOS code blank. The upstream connector partitions
on every source column when removing duplicates, so two copies of the same
claim version stop matching as soon as one of those columns changes, and both
survive into the adjustment logic. This fork partitions on the claim ID, line
number, adjustment type and effective date, and keeps the most recently
delivered copy.

**The final version carries its own amounts.** The upstream connector sums paid
and allowed amounts across every version in a related set and attaches the
total to the latest version, which is the section 5.3.1 method applied at the
line level. That double counts whenever a re-delivered copy is still in the
set. A replacement claim is a full restatement, so this fork takes the paid and
allowed amounts from the version that wins the sort and leaves the other
versions out of the total.

**Winning cancellations are dropped, and sets of originals stay separate.**
When the latest version in a set is a cancellation and the replacement was
billed under a different natural key, the set should net to zero. This fork
drops the cancellation rather than keeping it as a negative line. When a set
holds only original claims with no cancellation or replacement among them, CMS
treats each one as a final-action claim, so the group key falls back to the
claim ID and each original is kept as its own line.

Three singular tests in `tests/` guard this behavior: one row per claim version
in the ADR models, sets of originals are never collapsed, and no winning
cancellation reaches the deduped models.

### What we found in our data

We measured these changes against roughly ten years of CCLF history for one
ACO before making them.

- Nearly every related set that looked like two originals on one natural key
  turned out to be the same claim ID delivered again in a later monthly file,
  identical on every claim, service and dollar column. About 3 percent of Part
  B physician lines were affected, and summing across those copies would have
  overstated paid amounts by a low single-digit percentage in older years.
- We did not find any Part B sets with two distinct claim IDs and different
  HCPCS codes on one natural key. A few thousand such sets appeared on Part A
  over ten years, with differing DRGs.
- Winning cancellations with no replacement on the same key made up about one
  percent of institutional sets. Keeping them as negative lines understated
  institutional paid amounts by roughly one percent.

### Monthly and weekly CCLF releases

CMS sends ACOs a monthly CCLF release and, on request, weekly claims releases
that arrive between the monthly ones. Weekly files let you see recent claims
sooner, but a weekly release for a month is superseded once the monthly
release for that month arrives. This fork treats the eight file types (CCLF 1,
2, 3, 4, 5, 6, 8 and 9) that share a cadence and release date as one release,
and selects releases with these rules:

1. A release is eligible only when all eight file types are present.
2. For each performance year and month, a complete monthly release is used.
3. If no complete monthly release exists for that month, complete weekly
   releases are used instead.

The selected cadence is carried through every model as `file_cadence`
(`monthly` or `weekly`) with a matching `file_priority` (1 or 2), and the
priority is the first sort key wherever the connector picks between versions of
a row. `int_cclf_file_manifest` lists every file found, and
`int_selected_cclf_file_manifest` lists the releases that were chosen. Tests in
`tests/` check that selected releases are complete and that a weekly release
never outranks a complete monthly one.

Weekly support is off by default. To turn it on, load the weekly files into
their own tables, then set in `dbt_project.yml`:

```yaml
vars:
  cclf_weekly_enabled: true
  cclf_weekly_schema: <schema holding the weekly tables>
  cclf_weekly_identifier_suffix: _weekly
```

With weekly support off the connector still reads only complete monthly
releases, so a partial delivery waits until the rest of its files arrive.

Every raw CCLF table must have a `filename` column holding the CMS file name
(for example `P.A1234.ACO.ZC1Y24.D240215.T1234567`) and an `ingest_datetime`
column. The performance year and release date are read from the file name.

### Source configuration

Raw table locations are set with dbt variables so the same models run against
different layouts without editing the project.

| Variable | Default | Purpose |
| --- | --- | --- |
| `cclf_raw_database` | target database | Database or lakehouse holding the raw tables |
| `cclf_monthly_schema` | `<target schema>_team_cclf_raw` | Schema holding the monthly CCLF tables and ALR inputs |
| `cclf_weekly_schema` | same as monthly | Schema holding the weekly CCLF tables |
| `cclf_identifier_prefix` | `cclf_` | Prefix used to build the CCLF 1 to 9 table names |
| `cclf_weekly_identifier_suffix` | `_weekly` | Suffix added to the weekly table names |
| `cclf_weekly_enabled` | `false` | Read weekly releases |
| `alr_identifier` | `alr_1_1` | Prospective ALR 1-1 table |
| `alr_retro_identifier` | `alr_1_1_retro` | Retrospective ALR 1-1 table |
| `custom_attribution_identifier` | `mssp_attribution` | Provider attribution roster |
| `custom_attribution_enabled` | `true` | Set false when you have no roster; `provider_attribution` is then empty |
| `bnex_enabled` | `false` | Drop claims for beneficiaries who declined data sharing |
| `bnex_identifier` | `cclf_bnex` | CMS beneficiary exclusion (BNEX) table |

Any single table can be overridden with `cclf_<n>_identifier` or
`cclf_<n>_weekly_identifier`, which take precedence over the prefix and suffix.

### Eligibility and attribution from ALR files

The upstream connector expects you to supply an `enrollment` table with
enrollment spans or member months, or to run Tuva's separate `cms_alr_connector`
package and set `cms_alr_connector: true` so eligibility is built from its
output. This fork reads the Assignment List Report files directly and builds
eligibility inside the connector:

- `stg_alr_1_1` and `stg_alr_1_1_retro` stage the prospective and retrospective
  ALR 1-1 tables. When more than one ALR file exists for a performance year,
  the annual file is preferred over the quarterly ones, and later quarters over
  earlier ones. `int_alr_1_1_union` combines the two.
- `int_enrollment_stage` builds member months by taking each monthly CCLF8
  demographics snapshot and keeping the beneficiaries the ALR marks as assigned
  and not excluded for that performance year. Months after a beneficiary's
  death are dropped, and where several CCLF8 files cover a month, the file from
  the same year as the ALR is preferred.
- `eligibility` joins those months to CCLF8 demographics, with Medicare status,
  dual status and buy-in taken month by month from
  `int_beneficiary_demographics_monthly`. `int_orec_code` carries the last
  non-null original entitlement reason forward, because CCLF8 stops sending it
  after a beneficiary dies and the CMS-HCC model needs it.
- `provider_attribution` comes from an attribution roster you supply at member
  and year grain (`custom_attribution_identifier`) and is expanded to months
  using the Tuva calendar, with historical MBIs mapped to the current MBI
  through CCLF9. Set `custom_attribution_enabled` to false if you have no
  roster.

Beneficiary MBIs are normalized through CCLF9 in every one of these paths, in
line with section 5.1.1 of the Information Packet.

### Other changes from the upstream connector

**Institutional header payments follow the lowest surviving line.** When the
revenue center lines of a Part A claim do not sum to the header payment, the
connector places the header payment and the IME, DSH and uncompensated care
amounts on a single line. Upstream that line is always line 1. After
deduplication line 1 is not always present, so this fork uses the lowest line
number that survived, and a test confirms header payments are never dropped.

**Beneficiaries who declined data sharing can be excluded.** CMS sends MSSP
ACOs a beneficiary exclusion (BNEX) file. With `bnex_enabled` set to true the
connector reads it from `bnex_identifier` (columns `mbi`, `performance_year`,
`report_month`, `bene_exc_reason`) and drops medical claims for beneficiaries
with reason `BD` from the performance year of the exclusion onward. MBIs in
the file are mapped to the current MBI through CCLF9.

### Fabric support

The `macros/` folder carries Fabric overrides for `cast_numeric`,
`create_table_as` and `quote_column`. Other adapters use the Tuva defaults.
Microsoft Fabric is the platform this fork is tested on.
<br/><br/>

## 🧰 What does this repo do?

The Medicare CCLF Connector is a dbt project that maps raw Medicare CCLF claims data to the Tuva Input Layer, which is the first step in running the Tuva Project.  This connector expects your CCLF data to be organized into the tables outlined in this [CMS data dictionary](https://www.cms.gov/files/document/cclf-information-packet.pdf), which is the most recent format CMS uses to distribute CCLF files.
<br/><br/>  

## 🔌 Database Support

- BigQuery
- Redshift
- Snowflake
- Microsoft Fabric
<br/><br/>  

## ✅ Quickstart Guide

### Step 1: Clone or Fork this Repository
Unlike [the Tuva Project](https://github.com/tuva-health/the_tuva_project), this repo is a dbt project, not a dbt package.  Clone or fork this repository to your local machine.
<br/><br/> 

### Step 2: Import the Tuva Project
Next you need to import the Tuva Project dbt package into the Medicare CCLF Connector dbt project.  For example, using dbt CLI you would `cd` into the directly where you cloned this project to and run `dbt deps` to import the latest version of the Tuva Project.
<br/><br/> 

### Step 3: Data Preparation

#### Source data:
The source table names the connector is expecting can be found in the 
`_sources.yml` config file. You can rename your source tables if needed or add an 
alias to the config.  

#### File Dates:
The field `file_date` is used throughout this connector to deduplicate data 
received across regular and run-out CCLFs. We recommend parsing this date from 
the filename (e.g., P.A****.ACO.ZC1Y**.Dyymmdd.Thhmmsst) and formatting it as 
"YYYY-MM-DD".

#### Enrollment Dates:
The CCLF specification does not have a field that can be mapped directly 
to `enrollment_start_date` and `enrollment_end_date`, and the Part A and Part B 
entitlement dates (BENE_PART_A_ENRLMT_BGN_DT, BENE_PART_B_ENRLMT_BGN_DT) are 
often incorrect or not useful for claims analytics.

We have included an additional source called `Enrollment` that can be
populated with enrollment dates relevant to your data. These enrollment
dates may come from an attribution file, beneficiary alignment report (BAR), or
any source you may have. You just need to create a source table with the 
following columns:

  1. `current_bene_mbi_id`
  2. `enrollment_start_date`
  3. `enrollment_end_date`
  4. `bene_member_month`
     * The connector includes logic to handle enrollment spans or member months.
     * If enrollment spans are available, leave this field null.
     * If enrollment spans are not available, populate this field with member 
       month dates in the format "YYYY-MM-DD" and set the variable 
       `member_months_enrollment` to true in the `dbt_project.yml` file.
<br/><br/> 

### Step 4: Configure Input Database and Schema
Next you need to tell dbt where your Medicare CCLF source data is located.  Do this using the variables `input_database` and `input_schema` in the `dbt_project.yml` file.  You also need to configure your `profile` in the `dbt_project.yml`.
<br/><br/> 

### Step 5: Run
Finally, run the connector and the Tuva Project. For example, using dbt CLI you would `cd` to the project root folder in the command line and execute `dbt build`.  

Now you're ready to do claims data analytics!
<br/><br/>

## 🙋🏻‍♀️ How do I contribute?
Have an opinion on the mappings? Notice any bugs when installing and running the project?
If so, we highly encourage and welcome feedback!  While we work on a formal process in Github, we can be easily reached on our Slack community.
<br/><br/>

## 🤝 Join our community!
Join our growing community of healthcare data practitioners on [Slack](https://join.slack.com/t/thetuvaproject/shared_invite/zt-16iz61187-G522Mc2WGA2mHF57e0il0Q)!
