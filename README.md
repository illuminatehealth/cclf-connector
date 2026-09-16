[![Apache License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) ![dbt logo and version](https://img.shields.io/static/v1?logo=dbt&label=dbt-version&message=1.x&color=orange)

# Medicare CCLF Connector

## 🔗 Docs
Check out our [docs](https://thetuvaproject.com/) to learn about the project and how you can use it.
<br/><br/>

## 🩹 What is patched in this fork?

This is Illuminate Health's maintained fork of the Tuva Medicare CCLF Connector.
It runs in production for Medicare Shared Savings Program ACOs on Microsoft
Fabric, and it carries changes to the related-claims adjustment logic that we
have not yet sent upstream. Everything else follows the Tuva connector.

### Adjustment logic changes

CMS delivers several versions of a claim over time: the original, cancels
(`CLM_ADJSMT_TYPE_CD = 1`) and replacements (`CLM_ADJSMT_TYPE_CD = 2`). The
connector groups versions by the natural key CMS defines and resolves each
group to one final claim. Three parts of that flow are different here, in
`int_physician_claim_adr`, `int_dme_claim_adr`, `int_institutional_claim_adr`
and the matching `*_claim_deduped` models.

**1. Dedupe on claim identity, not the full row.** The upstream connector
removes duplicate deliveries by partitioning on every source column. CMS
re-delivers claims across monthly files, and later file layouts blank columns
such as the HIC number and BETOS code, so two copies of the same claim version
no longer match and both survive. The dedupe here partitions on claim ID, line
number, adjustment type and effective date, and keeps the latest delivery.

**2. Keep the winning version's own amounts.** Upstream sums paid and allowed
amounts across every version in a natural-key group and attaches the sum to
the latest version. With re-delivered copies in the group that double counts.
Here the winning version carries only its own amounts. A replacement is a full
restatement of the claim, so no summing is needed.

**3. Drop a winning cancel. Pass multiple originals through.** When the latest
version in a group is a cancel and its replacement was billed under a different
natural key, the group nets to zero and the cancel is dropped rather than kept
as a negative row. When a group holds only original claims and no cancel or
replacement, CMS treats each as a final-action claim, so the group key falls
back to the claim ID and each original stays its own line.

### What we found in our data

We measured these against roughly ten years of CCLF history for one ACO
before making the changes.

- Groups that looked like "two originals on one natural key" were almost all
  the same claim ID re-delivered in a second monthly file, identical on every
  claim, service and dollar column. About 3 percent of Part B physician lines
  were affected. Summing across those copies would have overstated paid
  amounts by low single-digit percent in the older years.
- Genuinely distinct claim IDs with different HCPCS on one natural key did not
  occur on the Part B side. A few thousand appeared on Part A over ten years
  with differing DRGs.
- Winning cancels with no replacement on the same key were about one percent
  of institutional groups. Keeping them as negative rows understated
  institutional paid amounts by roughly one percent.

Three singular tests in `tests/` guard the new behavior: one row per claim
version in the ADR models, original-only groups are never collapsed, and no
winning cancel reaches the deduped models.

### Fabric support

The `macros/` folder carries Fabric overrides for `cast_numeric`,
`create_table_as` and `quote_column`. Other adapters use the Tuva defaults.
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
