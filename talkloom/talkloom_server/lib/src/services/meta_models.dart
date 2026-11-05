/// Base URL of the Meta Model API, shared by every service.
const kMetaBaseUrl = 'https://api.meta.ai/v1';

/// Chat model used by Meta text-only calls (lesson compiler, tutor,
/// translation, evaluator). Change it here only.
const kMetaTextModel = 'muse-spark-1.3-contributor';

/// Model for calls that send images or video (OCR, video understanding).
/// Kept on the standard model: image/video input is not verified for the
/// contributor model, and the OCR path swallows failures silently.
const kMetaMultimodalModel = 'muse-spark-1.3';
