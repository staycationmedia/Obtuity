


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";





SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."blacklist_subids" (
    "id" integer NOT NULL,
    "publisher_id" integer,
    "subid" "text" NOT NULL,
    "reason" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."blacklist_subids" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."blacklist_subids_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."blacklist_subids_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."blacklist_subids_id_seq" OWNED BY "public"."blacklist_subids"."id";



CREATE TABLE IF NOT EXISTS "public"."clicks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "timestamp" timestamp with time zone DEFAULT "now"(),
    "publisher_id" integer,
    "subid" "text",
    "ip_hash" "text" NOT NULL,
    "country" "text",
    "device" "text",
    "user_agent" "text",
    "winner_partner_id" integer,
    "raw_payout" numeric(10,4),
    "margin_applied" numeric(10,4),
    "net_payout" numeric(10,4),
    "outcome" "text" NOT NULL,
    "router_time_ms" integer,
    "redirect_url" "text",
    CONSTRAINT "clicks_device_check" CHECK (("device" = ANY (ARRAY['mobile'::"text", 'desktop'::"text", 'tablet'::"text", 'unknown'::"text"]))),
    CONSTRAINT "clicks_outcome_check" CHECK (("outcome" = ANY (ARRAY['fill'::"text", 'no-fill'::"text", 'error'::"text", 'blacklist'::"text", 'invalid'::"text"])))
);


ALTER TABLE "public"."clicks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."feed_attempts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "click_id" "uuid",
    "partner_id" integer,
    "response_time_ms" integer,
    "payout" numeric(10,4),
    "fill" boolean DEFAULT false,
    "error" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."feed_attempts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."partners" (
    "id" integer NOT NULL,
    "name" "text" NOT NULL,
    "endpoint_url" "text" NOT NULL,
    "timeout_ms" integer DEFAULT 250,
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "partners_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'paused'::"text"])))
);


ALTER TABLE "public"."partners" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."partners_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."partners_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."partners_id_seq" OWNED BY "public"."partners"."id";



CREATE TABLE IF NOT EXISTS "public"."publishers" (
    "id" integer NOT NULL,
    "name" "text" NOT NULL,
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "rate_limit_per_minute" integer DEFAULT 1000,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "publishers_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'paused'::"text", 'blocked'::"text"])))
);


ALTER TABLE "public"."publishers" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."publishers_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."publishers_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."publishers_id_seq" OWNED BY "public"."publishers"."id";



CREATE TABLE IF NOT EXISTS "public"."rules_margins" (
    "id" integer NOT NULL,
    "rule_type" "text" NOT NULL,
    "geo" "text",
    "partner_id" integer,
    "publisher_id" integer,
    "margin_percent" numeric(5,2) NOT NULL,
    "priority" integer NOT NULL,
    "active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "rules_margins_rule_type_check" CHECK (("rule_type" = ANY (ARRAY['geo+partner'::"text", 'geo'::"text", 'publisher'::"text", 'partner'::"text", 'global'::"text"])))
);


ALTER TABLE "public"."rules_margins" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."rules_margins_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."rules_margins_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."rules_margins_id_seq" OWNED BY "public"."rules_margins"."id";



ALTER TABLE ONLY "public"."blacklist_subids" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."blacklist_subids_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."partners" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."partners_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."publishers" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."publishers_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."rules_margins" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."rules_margins_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."blacklist_subids"
    ADD CONSTRAINT "blacklist_subids_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."blacklist_subids"
    ADD CONSTRAINT "blacklist_subids_publisher_id_subid_key" UNIQUE ("publisher_id", "subid");



ALTER TABLE ONLY "public"."clicks"
    ADD CONSTRAINT "clicks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."feed_attempts"
    ADD CONSTRAINT "feed_attempts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."partners"
    ADD CONSTRAINT "partners_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."publishers"
    ADD CONSTRAINT "publishers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."rules_margins"
    ADD CONSTRAINT "rules_margins_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_blacklist_lookup" ON "public"."blacklist_subids" USING "btree" ("publisher_id", "subid");



CREATE INDEX "idx_clicks_country" ON "public"."clicks" USING "btree" ("country", "timestamp" DESC);



CREATE INDEX "idx_clicks_outcome" ON "public"."clicks" USING "btree" ("outcome", "timestamp" DESC);



CREATE INDEX "idx_clicks_publisher" ON "public"."clicks" USING "btree" ("publisher_id", "timestamp" DESC);



CREATE INDEX "idx_clicks_timestamp" ON "public"."clicks" USING "btree" ("timestamp" DESC);



CREATE INDEX "idx_feed_attempts_click" ON "public"."feed_attempts" USING "btree" ("click_id");



CREATE INDEX "idx_feed_attempts_partner" ON "public"."feed_attempts" USING "btree" ("partner_id", "created_at" DESC);



ALTER TABLE ONLY "public"."blacklist_subids"
    ADD CONSTRAINT "blacklist_subids_publisher_id_fkey" FOREIGN KEY ("publisher_id") REFERENCES "public"."publishers"("id");



ALTER TABLE ONLY "public"."clicks"
    ADD CONSTRAINT "clicks_publisher_id_fkey" FOREIGN KEY ("publisher_id") REFERENCES "public"."publishers"("id");



ALTER TABLE ONLY "public"."clicks"
    ADD CONSTRAINT "clicks_winner_partner_id_fkey" FOREIGN KEY ("winner_partner_id") REFERENCES "public"."partners"("id");



ALTER TABLE ONLY "public"."feed_attempts"
    ADD CONSTRAINT "feed_attempts_click_id_fkey" FOREIGN KEY ("click_id") REFERENCES "public"."clicks"("id");



ALTER TABLE ONLY "public"."feed_attempts"
    ADD CONSTRAINT "feed_attempts_partner_id_fkey" FOREIGN KEY ("partner_id") REFERENCES "public"."partners"("id");



ALTER TABLE ONLY "public"."rules_margins"
    ADD CONSTRAINT "rules_margins_partner_id_fkey" FOREIGN KEY ("partner_id") REFERENCES "public"."partners"("id");



ALTER TABLE ONLY "public"."rules_margins"
    ADD CONSTRAINT "rules_margins_publisher_id_fkey" FOREIGN KEY ("publisher_id") REFERENCES "public"."publishers"("id");



CREATE POLICY "Service role full access to blacklist_subids" ON "public"."blacklist_subids" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Service role full access to clicks" ON "public"."clicks" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Service role full access to feed_attempts" ON "public"."feed_attempts" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Service role full access to partners" ON "public"."partners" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Service role full access to publishers" ON "public"."publishers" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Service role full access to rules_margins" ON "public"."rules_margins" TO "service_role" USING (true) WITH CHECK (true);



ALTER TABLE "public"."blacklist_subids" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."clicks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."feed_attempts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."partners" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."publishers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."rules_margins" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";








































































































































































GRANT ALL ON TABLE "public"."blacklist_subids" TO "anon";
GRANT ALL ON TABLE "public"."blacklist_subids" TO "authenticated";
GRANT ALL ON TABLE "public"."blacklist_subids" TO "service_role";



GRANT ALL ON SEQUENCE "public"."blacklist_subids_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."blacklist_subids_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."blacklist_subids_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."clicks" TO "anon";
GRANT ALL ON TABLE "public"."clicks" TO "authenticated";
GRANT ALL ON TABLE "public"."clicks" TO "service_role";



GRANT ALL ON TABLE "public"."feed_attempts" TO "anon";
GRANT ALL ON TABLE "public"."feed_attempts" TO "authenticated";
GRANT ALL ON TABLE "public"."feed_attempts" TO "service_role";



GRANT ALL ON TABLE "public"."partners" TO "anon";
GRANT ALL ON TABLE "public"."partners" TO "authenticated";
GRANT ALL ON TABLE "public"."partners" TO "service_role";



GRANT ALL ON SEQUENCE "public"."partners_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."partners_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."partners_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."publishers" TO "anon";
GRANT ALL ON TABLE "public"."publishers" TO "authenticated";
GRANT ALL ON TABLE "public"."publishers" TO "service_role";



GRANT ALL ON SEQUENCE "public"."publishers_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."publishers_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."publishers_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."rules_margins" TO "anon";
GRANT ALL ON TABLE "public"."rules_margins" TO "authenticated";
GRANT ALL ON TABLE "public"."rules_margins" TO "service_role";



GRANT ALL ON SEQUENCE "public"."rules_margins_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."rules_margins_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."rules_margins_id_seq" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































