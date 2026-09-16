select
      hicn_mbi_xref_ind
    , crnt_num
    , prvs_num
    , prvs_id_efctv_dt
    , prvs_id_obslt_dt
    , bene_rrb_num
    , filename as file_name
    , {{ cclf_file_date('filename') }} as file_date
    , ingest_datetime
    , file_cadence
    , file_priority
from {{ ref('int_selected_cclf_9') }}