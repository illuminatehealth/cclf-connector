{{ config(tags=['connector']) }}

with institutional_claims as (

    select
          claim_id
        , sum(cast(paid_amount as decimal(18, 2))) as modeled_paid_amount
        , sum(case when cast(claim_line_number as integer) = 1 then 1 else 0 end) as line_1_rows
        , sum(case when paid_source = 'header payments' then 1 else 0 end) as header_payment_rows
    from {{ ref('medical_claim') }}
    where claim_type = 'institutional'
    group by claim_id

)

, raw_header as (

    select
          cur_clm_uniq_id as claim_id
        , cast(clm_pmt_amt as decimal(18, 2)) as header_paid_amount
        , row_number() over (
            partition by cur_clm_uniq_id
            order by file_date desc, file_name desc
          ) as header_rank
    from {{ ref('stg_parta_claims_header') }}

)

, raw_lines as (

    select
          cur_clm_uniq_id as claim_id
        , cast(clm_line_num as integer) as claim_line_number
        , cast(clm_line_cvrd_pd_amt as decimal(18, 2)) as line_paid_amount
        , row_number() over (
            partition by cur_clm_uniq_id, clm_line_num
            order by file_date desc, file_name desc
          ) as line_rank
    from {{ ref('stg_parta_claims_revenue_center_detail') }}

)

, raw_line_summary as (

    select
          claim_id
        , sum(line_paid_amount) as line_paid_amount
        , min(claim_line_number) as min_claim_line_number
        , sum(case when claim_line_number = 1 then 1 else 0 end) as line_1_rows
    from raw_lines
    where line_rank = 1
    group by claim_id

)

select
      c.claim_id
    , h.header_paid_amount
    , l.line_paid_amount
    , l.min_claim_line_number
    , c.modeled_paid_amount
    , c.header_payment_rows
from institutional_claims c
inner join raw_header h
    on c.claim_id = h.claim_id
   and h.header_rank = 1
left join raw_line_summary l
    on c.claim_id = l.claim_id
where h.header_paid_amount <> coalesce(l.line_paid_amount, 0)
  and h.header_paid_amount <> 0
  and c.modeled_paid_amount = 0
  and c.header_payment_rows = 0
