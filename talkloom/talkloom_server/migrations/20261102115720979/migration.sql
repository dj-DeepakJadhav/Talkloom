BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "vocab_artworks" (
    "id" bigserial PRIMARY KEY,
    "lemmaKey" text NOT NULL,
    "language" text NOT NULL,
    "styleVersion" bigint NOT NULL DEFAULT 1,
    "mimeType" text NOT NULL,
    "artwork" bytea NOT NULL,
    "hitCount" bigint NOT NULL DEFAULT 0,
    "createdAt" timestamp without time zone NOT NULL,
    "lastUsedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "artwork_lemma_style_idx" ON "vocab_artworks" USING btree ("lemmaKey", "styleVersion");


--
-- MIGRATION VERSION FOR talkloom
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talkloom', '20261102115720979', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261102115720979', "timestamp" = now();

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
