let OpenAI;

try {
  const openAiModule = require('openai');
  OpenAI = openAiModule?.default || openAiModule;
} catch (error) {
  OpenAI = null;
}

const OPENROUTER_BASE_URL = 'https://openrouter.ai/api/v1';
const DEFAULT_SUMMARY_MODEL = 'openai/gpt-4o-mini';

let cachedClient = null;
let cachedSignature = '';

const createAiClientError = (message, code, httpStatus = 503, reason = null) => {
  const error = new Error(message);
  error.code = code;
  error.httpStatus = httpStatus;
  if (reason) {
    error.reason = reason;
  }
  return error;
};

const getSummaryModel = () => {
  const model = String(
    process.env.OPENROUTER_MODEL || process.env.OPENAI_SUMMARY_MODEL || DEFAULT_SUMMARY_MODEL
  ).trim();
  return model || DEFAULT_SUMMARY_MODEL;
};

const getOpenRouterBaseUrl = () =>
  String(process.env.OPENROUTER_BASE_URL || OPENROUTER_BASE_URL).trim() || OPENROUTER_BASE_URL;

const getAiClient = () => {
  if (!OpenAI) {
    throw createAiClientError(
      'AI SDK is missing. Run npm install in backend.',
      'AI_CLIENT_SDK_MISSING',
      500,
      'sdk_missing'
    );
  }

  const apiKey = String(process.env.OPENAI_API_KEY || '').trim();
  if (!apiKey) {
    throw createAiClientError(
      'AI API key missing in environment.',
      'AI_CLIENT_KEY_MISSING',
      500,
      'missing_api_key'
    );
  }

  const baseURL = getOpenRouterBaseUrl();
  const timeout = Number(process.env.AI_TIMEOUT_MS || 45000);
  const referer = String(process.env.OPENROUTER_HTTP_REFERER || process.env.APP_PUBLIC_URL || '').trim();
  const title = String(process.env.OPENROUTER_APP_NAME || process.env.APP_NAME || 'DU Alert').trim();

  const signature = `${apiKey}|${baseURL}|${timeout}|${referer}|${title}`;
  if (cachedClient && cachedSignature === signature) {
    return cachedClient;
  }

  const defaultHeaders = {
    Authorization: `Bearer ${apiKey}`,
  };

  if (referer) {
    defaultHeaders['HTTP-Referer'] = referer;
  }

  if (title) {
    defaultHeaders['X-Title'] = title;
  }

  cachedClient = new OpenAI({
    apiKey,
    baseURL,
    timeout,
    defaultHeaders,
  });
  cachedSignature = signature;

  return cachedClient;
};

module.exports = {
  getAiClient,
  getSummaryModel,
  createAiClientError,
  OPENROUTER_BASE_URL,
};
