select
      hicn_mbi_xref_ind
    , crnt_num
    , prvs_num
    , prvs_id_efctv_dt
    , prvs_id_obslt_dt
    , bene_rrb_num
    , filename as file_name
    , cast({{ dbt.concat(["'20'", "substring(filename, 21, 2)", "'-'", "substring(filename, 23, 2)", "'-'", "substring(filename, 25, 2)"]) }} as date)  AS file_date
    , ingest_datetime
from {{ source('lakehouse','cclf_9') }}