/* This model was added as it appears that CCLF files stop sending the OREC code on a member's death,
which is used in CMS-HCC model. Here we pull in the last non-null value from the cclf 8 files.*/

with cte as (
select current_bene_mbi_id
,min(row_num) as first_non_null
from {{ ref('int_beneficiary_demographics_deduped') }}
where bene_orgnl_entlmt_rsn_cd is not null
group by current_bene_mbi_id
)

select d.current_bene_mbi_id
,d.bene_orgnl_entlmt_rsn_cd
from {{ ref('int_beneficiary_demographics_deduped') }} d
inner join cte on d.current_bene_mbi_id = cte.current_bene_mbi_id
and
cte.first_non_null = d. row_num