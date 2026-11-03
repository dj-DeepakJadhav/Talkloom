BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "link_analyses" (
    "id" bigserial PRIMARY KEY,
    "normalizedUrl" text NOT NULL,
    "platform" text NOT NULL,
    "creator" text,
    "creatorKey" text,
    "title" text NOT NULL,
    "targetLanguage" text NOT NULL,
    "supportLanguage" text NOT NULL,
    "cefrLevel" text NOT NULL,
    "transcript" text NOT NULL,
    "contentHash" text NOT NULL,
    "objectives" json NOT NULL,
    "vocabulary" text NOT NULL,
    "grammar" text NOT NULL,
    "activities" text NOT NULL,
    "conversationPlan" text NOT NULL,
    "hitCount" bigint NOT NULL DEFAULT 0,
    "createdAt" timestamp without time zone NOT NULL,
    "lastUsedAt" timestamp without time zone NOT NULL,
    "expiresAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "link_analysis_key_idx" ON "link_analyses" USING btree ("normalizedUrl", "targetLanguage", "supportLanguage", "cefrLevel");
CREATE INDEX "link_analysis_url_idx" ON "link_analyses" USING btree ("normalizedUrl", "targetLanguage");
CREATE INDEX "link_analysis_category_idx" ON "link_analyses" USING btree ("platform", "creatorKey");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "sources" ADD COLUMN "platform" text;
ALTER TABLE "sources" ADD COLUMN "creator" text;

--
-- MIGRATION VERSION FOR talkloom
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talkloom', '20261014075035191', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261014075035191', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260924105404509', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105404509', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260924105232991', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105232991', "timestamp" = now();


COMMIT;
