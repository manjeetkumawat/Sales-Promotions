use [retail_events_db]
go

----------- sript 1

select distinct
	dp.product_code,
	product_name,
	base_price,
	promo_type
from
    [fact_events] fe
inner join [dim_campaigns] dc on dc.campaign_id = fe.campaign_id
inner join [dim_products] dp on dp.product_code=fe.product_code
where
    fe.base_price > 500
    and fe.promo_type = 'bogof'

----------- sript 2
select count(*) total_store,city from [dim_stores] group by city 
order by 1 desc


----------- sript 3
select
    dc.campaign_name,
    coalesce(sum(fe.base_price * fe.quantity_sold_before_promo), 0) / 1000000 as total_revenue_bp_millions,
    coalesce(sum(fe.base_price * fe.quantity_sold_after_promo), 0) / 1000000 as total_revenue_ap_millions
from
    [fact_events] fe
inner join
    [dim_campaigns] dc on dc.campaign_id = fe.campaign_id
where
    (fe.quantity_sold_before_promo > 0 or fe.quantity_sold_after_promo > 0)
group by
    dc.campaign_name

----------- sript 4

;with categoryisu as (
    select
        dp.category,
        (sum(fe.quantity_sold_after_promo) - sum(fe.quantity_sold_before_promo)) * 100.0 / nullif(sum(fe.quantity_sold_before_promo), 0) as isu_percentage
    from
        [fact_events] fe
    inner join
        [dim_campaigns] dc on dc.campaign_id = fe.campaign_id
	inner join 
		[dim_products] dp on dp.product_code=fe.product_code
    where
        dc.campaign_name = 'diwali'
        and fe.quantity_sold_before_promo > 0
        and fe.quantity_sold_after_promo > 0
    group by
        dp.category
)
select
    category,
    isu_percentage,
    rank() over (order by isu_percentage desc) as rank_order
from
    categoryisu
order by
    isu_percentage desc


----------- sript 5
;with productir as (
    select
        dp.product_name,
        dp.category,
        coalesce(sum(fe.base_price * fe.quantity_sold_after_promo), 0) - coalesce(sum(fe.base_price * fe.quantity_sold_before_promo), 0) as incremental_revenue,
        coalesce(sum(fe.base_price * fe.quantity_sold_before_promo), 0) as revenue_before_promo
    from
        [fact_events] fe
    inner join
        [dim_campaigns] dc on dc.campaign_id = fe.campaign_id
	inner join
       [dim_products] dp on dp.product_code=fe.product_code
    where
        fe.quantity_sold_before_promo > 0 and fe.quantity_sold_after_promo > 0
    group by
        dp.product_name, dp.category
),
rankedproducts as (
    select
        product_name,
        category,
        (incremental_revenue / nullif(revenue_before_promo, 0)) * 100 as ir_percentage,
        rank() over (order by (incremental_revenue / nullif(revenue_before_promo, 0)) desc) as rank_order
    from
        productir
)
select
    product_name,
    category,
    ir_percentage
from
    rankedproducts
where
    rank_order <= 5
order by
    rank_order


	--select * from [dim_stores]
	--select * from [fact_events]





