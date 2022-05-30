
drop table if exists distinct_in_order sync;
create table distinct_in_order (a int, b int, c int) engine=MergeTree() order by (a, b, c);

select 'disable optimize_distinct_in_order';
set optimize_distinct_in_order=0;
select 'pipeline does _not_ contain the optimization';
explain pipeline select distinct * from distinct_in_order settings max_threads=1;

select 'enable optimize_distinct_in_order';
set optimize_distinct_in_order=1;
select 'distinct with primary key prefix -> pipeline contains the optimization';
explain pipeline select distinct a, c from distinct_in_order settings max_threads=1;
select 'distinct with non-primary key prefix -> pipeline does _not_ contain the optimization';
explain pipeline select distinct b, c from distinct_in_order settings max_threads=1;

select 'the same values in every chunk, distinct in order should skip entire chunks with the same key as previous one';
drop table if exists distinct_in_order sync;
create table distinct_in_order (a int) engine=MergeTree() order by a;
insert into distinct_in_order (a) select * from zeros(1000000);
select 'single-threaded distinct';
select distinct * from distinct_in_order settings max_threads=1;
select 'multi-threaded distinct';
select distinct * from distinct_in_order;

select 'chunks can contain values from previous one';
drop table if exists distinct_in_order sync;
create table distinct_in_order (a int) engine=MergeTree() order by a settings index_granularity=3;
insert into distinct_in_order select * from numbers(10);
insert into distinct_in_order select * from numbers(10);
insert into distinct_in_order select * from numbers(10);
select 'single-threaded distinct';
select distinct a from distinct_in_order settings max_block_size=3, max_threads=1;
select 'multi-threaded distinct';
select distinct a from distinct_in_order settings max_block_size=3;
drop table if exists distinct_in_order sync;
