BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "source_translation_chunk" (
    "id" bigserial PRIMARY KEY,
    "userId" text NOT NULL,
    "sourceId" bigint NOT NULL,
    "cacheKey" text NOT NULL,
    "supportLanguage" text NOT NULL,
    "mode" text NOT NULL,
    "segments" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "source_translation_cache_key" ON "source_translation_chunk" USING btree ("cacheKey");
CREATE INDEX "source_translation_owner_source" ON "source_translation_chunk" USING btree ("userId", "sourceId");


--
-- MIGRATION VERSION FOR talkloom
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talkloom', '20261104203723844', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261104203723844', "timestamp" = now();

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
