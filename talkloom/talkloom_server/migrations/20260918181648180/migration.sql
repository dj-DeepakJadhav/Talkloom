BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "lessons" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "lessons" (
    "id" bigserial PRIMARY KEY,
    "userId" text NOT NULL,
    "sourceId" bigint NOT NULL,
    "targetLanguage" text NOT NULL,
    "supportLanguage" text NOT NULL,
    "objectives" json NOT NULL,
    "vocabulary" text NOT NULL,
    "grammar" text NOT NULL,
    "activities" text NOT NULL,
    "conversationPlan" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "lesson_user_lang_idx" ON "lessons" USING btree ("userId", "targetLanguage");

--
-- ACTION DROP TABLE
--
DROP TABLE "sources" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "sources" (
    "id" bigserial PRIMARY KEY,
    "userId" text NOT NULL,
    "type" text NOT NULL,
    "url" text,
    "rawText" text NOT NULL,
    "title" text NOT NULL,
    "targetLanguage" text NOT NULL,
    "cefrLevel" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "source_user_lang_idx" ON "sources" USING btree ("userId", "targetLanguage");


--
-- MIGRATION VERSION FOR talkloom
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talkloom', '20260918181648180', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260918181648180', "timestamp" = now();

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
    VALUES ('serverpod_auth_idp', '20260910193913364-string-rate-limit-keys', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260910193913364-string-rate-limit-keys', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260824182354731', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182354731', "timestamp" = now();


COMMIT;
