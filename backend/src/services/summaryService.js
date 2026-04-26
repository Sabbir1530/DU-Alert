const { getAiClient, getSummaryModel } = require('./aiClient');

/**
 * Detect if text is primarily in Bangla or English
 * @param {string} text - The text to check
 * @returns {string} - 'bangla', 'english', or 'mixed'
 */
const detectLanguage = (text) => {
  if (!text) return 'english';

  // Bangla Unicode range: \u0980-\u09FF
  const banglaRegex = /[\u0980-\u09FF]/g;
  const englishRegex = /[a-zA-Z]/g;

  const banglaMatches = text.match(banglaRegex) || [];
  const englishMatches = text.match(englishRegex) || [];

  const banglaCount = banglaMatches.length;
  const englishCount = englishMatches.length;

  if (banglaCount === 0 && englishCount === 0) return 'english';
  if (banglaCount > englishCount * 1.5) return 'bangla';
  if (englishCount > banglaCount * 1.5) return 'english';

  return 'mixed';
};

const createSummaryServiceError = (message, code, httpStatus = 503, reason = null) => {
  const error = new Error(message);
  error.code = code;
  error.httpStatus = httpStatus;
  if (reason) {
    error.reason = reason;
  }
  return error;
};

const mapAiProviderError = (error) => {
  const status = Number(error?.status || 0);
  const code = String(error?.code || error?.error?.code || '').toLowerCase();
  const type = String(error?.type || error?.error?.type || '').toLowerCase();
  const message = String(error?.message || '').toLowerCase();

  if (code === 'insufficient_quota' || type === 'insufficient_quota') {
    return createSummaryServiceError(
      'AI summary quota exceeded. Please update OpenRouter billing or API key.',
      'AI_SUMMARY_QUOTA_EXCEEDED',
      503,
      'insufficient_quota'
    );
  }

  if (status === 401 || code === 'invalid_api_key' || message.includes('unauthorized')) {
    return createSummaryServiceError(
      'AI summary service misconfigured. Please contact administrator.',
      'AI_SUMMARY_INVALID_KEY',
      503,
      'invalid_api_key'
    );
  }

  if (
    code === 'model_not_found' ||
    type === 'model_not_found' ||
    message.includes('unsupported model') ||
    (message.includes('model') && message.includes('not found'))
  ) {
    return createSummaryServiceError(
      'AI summary model is not supported by provider. Update OPENROUTER_MODEL.',
      'AI_SUMMARY_UNSUPPORTED_MODEL',
      500,
      'unsupported_model'
    );
  }

  if (status === 429) {
    return createSummaryServiceError(
      'AI summary rate limit reached. Please try again shortly.',
      'AI_SUMMARY_RATE_LIMIT',
      503,
      'rate_limit'
    );
  }

  if (
    code === 'timeout' ||
    message.includes('timed out') ||
    ['etimedout', 'aborterror', 'aborted'].includes(code)
  ) {
    return createSummaryServiceError(
      'AI summary request timed out. Please try again.',
      'AI_SUMMARY_TIMEOUT',
      504,
      'timeout'
    );
  }

  if (
    ['enotfound', 'econnrefused', 'econnreset', 'eai_again', 'network_error', 'fetch_error'].includes(
      code
    ) ||
    message.includes('network') ||
    message.includes('fetch failed')
  ) {
    return createSummaryServiceError(
      'Network error while contacting AI provider. Please try again.',
      'AI_SUMMARY_NETWORK_ERROR',
      503,
      'network_failure'
    );
  }

  return createSummaryServiceError(
    'AI summary service unavailable. Please try again.',
    'AI_SUMMARY_UNAVAILABLE',
    503,
    'provider_unavailable'
  );
};

const buildPrompt = (complaintText, language) => {
  if (language === 'bangla') {
    return `নিচের অভিযোগটি স্পষ্টভাবে ২ থেকে ৪ লাইনে সংক্ষিপ্ত করুন। মূল সমস্যা, জরুরিতা, এবং গুরুত্বপূর্ণ তথ্য রাখুন। অভিযোগের এলোমেলো লাইন কপি করবেন না; মানবিক ও প্রাকৃতিকভাবে সারাংশ লিখুন।\n\nঅভিযোগ:\n${complaintText}`;
  }

  if (language === 'mixed') {
    return `Summarize the following complaint clearly in 2 to 4 lines. Keep the key issue, urgency, and important facts. Do not copy random lines. If the complaint uses both Bangla and English, produce a natural mixed-language summary.\n\nComplaint:\n${complaintText}`;
  }

  return `Summarize the following complaint clearly in 2 to 4 lines. Keep the key issue, urgency, and important facts. Do not copy random lines. Create a human-like summary.\n\nComplaint:\n${complaintText}`;
};

/**
 * Generate summary using OpenRouter API-compatible chat completions
 * @param {string} complaintText - The full complaint description
 * @returns {Promise<string>} - The generated summary
 */
const generateSummary = async (complaintText) => {
  const text = String(complaintText || '').trim();
  if (!text) {
    throw new Error('Complaint text is required');
  }

  const client = getAiClient();
  const summaryModel = getSummaryModel();

  const language = detectLanguage(text);
  const prompt = buildPrompt(text, language);

  try {
    const response = await client.chat.completions.create({
      model: summaryModel,
      messages: [
        {
          role: 'system',
          content:
            'You are an expert complaint summarizer. Always summarize the full complaint content and return only a concise, accurate 2 to 4 line summary.',
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
      max_tokens: 180,
      temperature: 0.3,
    });

    const summary = response.choices[0]?.message?.content?.trim();

    if (!summary) {
      throw createSummaryServiceError(
        'AI returned an empty summary. Please try again.',
        'AI_SUMMARY_EMPTY_RESPONSE',
        502,
        'empty_response'
      );
    }

    return summary;
  } catch (error) {
    if (error?.code?.startsWith('AI_')) {
      throw error;
    }

    console.error('AI Provider Error:', {
      message: error.message,
      status: error.status,
      code: error.code,
      type: error.type,
    });

    throw mapAiProviderError(error);
  }
};

module.exports = {
  generateSummary,
  detectLanguage,
};
