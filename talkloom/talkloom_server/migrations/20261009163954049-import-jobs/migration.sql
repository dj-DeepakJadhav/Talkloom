BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "import_jobs" (
    "id" bigserial PRIMARY KEY,
    "userId" text,
    "type" text NOT NULL,
    "title" text NOT NULL,
    "targetLanguage" text NOT NULL,
    "supportLanguage" text NOT NULL,
    "cefrLevel" text NOT NULL,
    "url" text,
    "rawContent" text,
    "stage" text NOT NULL DEFAULT 'queued'::text,
    "sourceId" bigint,
    "lessonId" bigint,
    "errorCode" text,
    "errorMessage" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "import_job_user_idx" ON "import_jobs" USING btree ("userId", "createdAt");


--
-- MIGRATION VERSION FOR talkloom
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talkloom', '20261009163954049-import-jobs', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261009163954049-import-jobs', "timestamp" = now();

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
