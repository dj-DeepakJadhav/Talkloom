BEGIN;

--
-- ACTION ALTER TABLE
--
DROP INDEX "source_user_lang_idx";
ALTER TABLE "sources" ADD COLUMN "isArchived" boolean NOT NULL DEFAULT false;
CREATE INDEX "source_url_lang_idx" ON "sources" USING btree ("url", "targetLanguage");
CREATE INDEX "source_user_lang_idx" ON "sources" USING btree ("userId", "targetLanguage", "isArchived");

--
-- MIGRATION VERSION FOR talkloom
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talkloom', '20261006122348053-archive-sources', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261006122348053-archive-sources', "timestamp" = now();

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
