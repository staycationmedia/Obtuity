drop extension if exists "pg_net";

drop policy "Service role full access to blacklist_subids" on "public"."blacklist_subids";

drop policy "Service role full access to clicks" on "public"."clicks";

drop policy "Service role full access to feed_attempts" on "public"."feed_attempts";

drop policy "Service role full access to partners" on "public"."partners";

drop policy "Service role full access to publishers" on "public"."publishers";

drop policy "Service role full access to rules_margins" on "public"."rules_margins";

revoke delete on table "public"."blacklist_subids" from "anon";

revoke insert on table "public"."blacklist_subids" from "anon";

revoke references on table "public"."blacklist_subids" from "anon";

revoke select on table "public"."blacklist_subids" from "anon";

revoke trigger on table "public"."blacklist_subids" from "anon";

revoke truncate on table "public"."blacklist_subids" from "anon";

revoke update on table "public"."blacklist_subids" from "anon";

revoke delete on table "public"."blacklist_subids" from "authenticated";

revoke insert on table "public"."blacklist_subids" from "authenticated";

revoke references on table "public"."blacklist_subids" from "authenticated";

revoke select on table "public"."blacklist_subids" from "authenticated";

revoke trigger on table "public"."blacklist_subids" from "authenticated";

revoke truncate on table "public"."blacklist_subids" from "authenticated";

revoke update on table "public"."blacklist_subids" from "authenticated";

revoke delete on table "public"."blacklist_subids" from "service_role";

revoke insert on table "public"."blacklist_subids" from "service_role";

revoke references on table "public"."blacklist_subids" from "service_role";

revoke select on table "public"."blacklist_subids" from "service_role";

revoke trigger on table "public"."blacklist_subids" from "service_role";

revoke truncate on table "public"."blacklist_subids" from "service_role";

revoke update on table "public"."blacklist_subids" from "service_role";

revoke delete on table "public"."clicks" from "anon";

revoke insert on table "public"."clicks" from "anon";

revoke references on table "public"."clicks" from "anon";

revoke select on table "public"."clicks" from "anon";

revoke trigger on table "public"."clicks" from "anon";

revoke truncate on table "public"."clicks" from "anon";

revoke update on table "public"."clicks" from "anon";

revoke delete on table "public"."clicks" from "authenticated";

revoke insert on table "public"."clicks" from "authenticated";

revoke references on table "public"."clicks" from "authenticated";

revoke select on table "public"."clicks" from "authenticated";

revoke trigger on table "public"."clicks" from "authenticated";

revoke truncate on table "public"."clicks" from "authenticated";

revoke update on table "public"."clicks" from "authenticated";

revoke delete on table "public"."clicks" from "service_role";

revoke insert on table "public"."clicks" from "service_role";

revoke references on table "public"."clicks" from "service_role";

revoke select on table "public"."clicks" from "service_role";

revoke trigger on table "public"."clicks" from "service_role";

revoke truncate on table "public"."clicks" from "service_role";

revoke update on table "public"."clicks" from "service_role";

revoke delete on table "public"."feed_attempts" from "anon";

revoke insert on table "public"."feed_attempts" from "anon";

revoke references on table "public"."feed_attempts" from "anon";

revoke select on table "public"."feed_attempts" from "anon";

revoke trigger on table "public"."feed_attempts" from "anon";

revoke truncate on table "public"."feed_attempts" from "anon";

revoke update on table "public"."feed_attempts" from "anon";

revoke delete on table "public"."feed_attempts" from "authenticated";

revoke insert on table "public"."feed_attempts" from "authenticated";

revoke references on table "public"."feed_attempts" from "authenticated";

revoke select on table "public"."feed_attempts" from "authenticated";

revoke trigger on table "public"."feed_attempts" from "authenticated";

revoke truncate on table "public"."feed_attempts" from "authenticated";

revoke update on table "public"."feed_attempts" from "authenticated";

revoke delete on table "public"."feed_attempts" from "service_role";

revoke insert on table "public"."feed_attempts" from "service_role";

revoke references on table "public"."feed_attempts" from "service_role";

revoke select on table "public"."feed_attempts" from "service_role";

revoke trigger on table "public"."feed_attempts" from "service_role";

revoke truncate on table "public"."feed_attempts" from "service_role";

revoke update on table "public"."feed_attempts" from "service_role";

revoke delete on table "public"."rules_margins" from "anon";

revoke insert on table "public"."rules_margins" from "anon";

revoke references on table "public"."rules_margins" from "anon";

revoke select on table "public"."rules_margins" from "anon";

revoke trigger on table "public"."rules_margins" from "anon";

revoke truncate on table "public"."rules_margins" from "anon";

revoke update on table "public"."rules_margins" from "anon";

revoke delete on table "public"."rules_margins" from "authenticated";

revoke insert on table "public"."rules_margins" from "authenticated";

revoke references on table "public"."rules_margins" from "authenticated";

revoke select on table "public"."rules_margins" from "authenticated";

revoke trigger on table "public"."rules_margins" from "authenticated";

revoke truncate on table "public"."rules_margins" from "authenticated";

revoke update on table "public"."rules_margins" from "authenticated";

revoke delete on table "public"."rules_margins" from "service_role";

revoke insert on table "public"."rules_margins" from "service_role";

revoke references on table "public"."rules_margins" from "service_role";

revoke select on table "public"."rules_margins" from "service_role";

revoke trigger on table "public"."rules_margins" from "service_role";

revoke truncate on table "public"."rules_margins" from "service_role";

revoke update on table "public"."rules_margins" from "service_role";

alter table "public"."blacklist_subids" drop constraint "blacklist_subids_publisher_id_fkey";

alter table "public"."blacklist_subids" drop constraint "blacklist_subids_publisher_id_subid_key";

alter table "public"."clicks" drop constraint "clicks_device_check";

alter table "public"."clicks" drop constraint "clicks_outcome_check";

alter table "public"."clicks" drop constraint "clicks_publisher_id_fkey";

alter table "public"."clicks" drop constraint "clicks_winner_partner_id_fkey";

alter table "public"."feed_attempts" drop constraint "feed_attempts_click_id_fkey";

alter table "public"."feed_attempts" drop constraint "feed_attempts_partner_id_fkey";

alter table "public"."partners" drop constraint "partners_status_check";

alter table "public"."publishers" drop constraint "publishers_status_check";

alter table "public"."rules_margins" drop constraint "rules_margins_partner_id_fkey";

alter table "public"."rules_margins" drop constraint "rules_margins_publisher_id_fkey";

alter table "public"."rules_margins" drop constraint "rules_margins_rule_type_check";

alter table "public"."blacklist_subids" drop constraint "blacklist_subids_pkey";

alter table "public"."clicks" drop constraint "clicks_pkey";

alter table "public"."feed_attempts" drop constraint "feed_attempts_pkey";

alter table "public"."rules_margins" drop constraint "rules_margins_pkey";

drop index if exists "public"."blacklist_subids_pkey";

drop index if exists "public"."blacklist_subids_publisher_id_subid_key";

drop index if exists "public"."clicks_pkey";

drop index if exists "public"."feed_attempts_pkey";

drop index if exists "public"."idx_blacklist_lookup";

drop index if exists "public"."idx_clicks_country";

drop index if exists "public"."idx_clicks_outcome";

drop index if exists "public"."idx_clicks_publisher";

drop index if exists "public"."idx_clicks_timestamp";

drop index if exists "public"."idx_feed_attempts_click";

drop index if exists "public"."idx_feed_attempts_partner";

drop index if exists "public"."rules_margins_pkey";

drop table "public"."blacklist_subids";

drop table "public"."clicks";

drop table "public"."feed_attempts";

drop table "public"."rules_margins";


  create table "public"."Feeds" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "endpoint" text,
    "active" boolean
      );


alter table "public"."Feeds" enable row level security;

alter table "public"."partners" drop column "created_at";

alter table "public"."partners" alter column "endpoint_url" drop not null;

alter table "public"."partners" alter column "id" drop default;

alter table "public"."partners" alter column "id" add generated by default as identity;

alter table "public"."partners" alter column "id" set data type bigint using "id"::bigint;

alter table "public"."partners" alter column "status" drop default;

alter table "public"."partners" alter column "status" drop not null;

alter table "public"."partners" alter column "timeout_ms" drop default;

alter table "public"."partners" alter column "timeout_ms" set data type bigint using "timeout_ms"::bigint;

alter table "public"."publishers" drop column "rate_limit_per_minute";

alter table "public"."publishers" drop column "status";

alter table "public"."publishers" add column "endpoint_url" text;

alter table "public"."publishers" add column "timeout_ms" bigint;

alter table "public"."publishers" alter column "created_at" set not null;

alter table "public"."publishers" alter column "id" set default gen_random_uuid();

alter table "public"."publishers" alter column "id" set data type uuid using "id"::uuid;

alter table "public"."publishers" alter column "name" drop not null;

drop sequence if exists "public"."blacklist_subids_id_seq";

drop sequence if exists "public"."partners_id_seq";

drop sequence if exists "public"."publishers_id_seq";

drop sequence if exists "public"."rules_margins_id_seq";

CREATE UNIQUE INDEX "Feeds_pkey" ON public."Feeds" USING btree (id);

alter table "public"."Feeds" add constraint "Feeds_pkey" PRIMARY KEY using index "Feeds_pkey";

grant delete on table "public"."Feeds" to "anon";

grant insert on table "public"."Feeds" to "anon";

grant references on table "public"."Feeds" to "anon";

grant select on table "public"."Feeds" to "anon";

grant trigger on table "public"."Feeds" to "anon";

grant truncate on table "public"."Feeds" to "anon";

grant update on table "public"."Feeds" to "anon";

grant delete on table "public"."Feeds" to "authenticated";

grant insert on table "public"."Feeds" to "authenticated";

grant references on table "public"."Feeds" to "authenticated";

grant select on table "public"."Feeds" to "authenticated";

grant trigger on table "public"."Feeds" to "authenticated";

grant truncate on table "public"."Feeds" to "authenticated";

grant update on table "public"."Feeds" to "authenticated";

grant delete on table "public"."Feeds" to "service_role";

grant insert on table "public"."Feeds" to "service_role";

grant references on table "public"."Feeds" to "service_role";

grant select on table "public"."Feeds" to "service_role";

grant trigger on table "public"."Feeds" to "service_role";

grant truncate on table "public"."Feeds" to "service_role";

grant update on table "public"."Feeds" to "service_role";


