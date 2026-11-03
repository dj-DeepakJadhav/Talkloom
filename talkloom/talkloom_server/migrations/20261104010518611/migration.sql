BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "ai_usage" (
    "id" bigserial PRIMARY KEY,
    "userId" text NOT NULL,
    "day" timestamp without time zone NOT NULL,
    "imports" bigint NOT NULL DEFAULT 0,
    "conversationTurns" bigint NOT NULL DEFAULT 0,
    "transcriptions" bigint NOT NULL DEFAULT 0,
    "illustrations" bigint NOT NULL DEFAULT 0
);

-- Indexes
CREATE UNIQUE INDEX "ai_usage_user_day_idx" ON "ai_usage" USING btree ("userId", "day");


--
-- MIGRATION VERSION FOR talkloom
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talkloom', '20261104010518611', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261104010518611', "timestamp" = now();

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
