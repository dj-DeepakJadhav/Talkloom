BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "turn_evaluations" (
    "id" bigserial PRIMARY KEY,
    "userId" text,
    "targetLanguage" text NOT NULL,
    "lessonId" bigint NOT NULL,
    "learnerUtterance" text,
    "status" text NOT NULL,
    "provider" text,
    "model" text,
    "reason" text,
    "results" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "turn_evaluation_user_lang_idx" ON "turn_evaluations" USING btree ("userId", "targetLanguage", "createdAt");


--
-- MIGRATION VERSION FOR talkloom
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talkloom', '20261009164635457-turn-evaluations', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261009164635457-turn-evaluations', "timestamp" = now();

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
