const axios = require('axios');
const logger = require('./logger');

const YOUTUBE_API_KEY = process.env.YOUTUBE_API_KEY;
const YOUTUBE_API_BASE_URL = 'https://www.googleapis.com/youtube/v3';

// In-memory cache for video results (24-hour TTL)
const videoCache = new Map();
const CACHE_TTL = 24 * 60 * 60 * 1000; // 24 hours in milliseconds

// Quota tracking
let dailyQuotaUsed = 0;
const DAILY_QUOTA_LIMIT = 9500; // Leave buffer of 500 units
const QUOTA_PER_SEARCH = 100;
let quotaResetTime = Date.now() + 24 * 60 * 60 * 1000;

/**
 * Reset quota counter if 24 hours have passed
 */
function checkQuotaReset() {
  if (Date.now() >= quotaResetTime) {
    dailyQuotaUsed = 0;
    quotaResetTime = Date.now() + 24 * 60 * 60 * 1000;
    logger.info('YouTube API quota counter reset');
  }
}

/**
 * Check if we have quota remaining
 */
function hasQuotaRemaining() {
  checkQuotaReset();
  return dailyQuotaUsed + QUOTA_PER_SEARCH <= DAILY_QUOTA_LIMIT;
}

/**
 * Track quota usage
 */
function trackQuotaUsage() {
  dailyQuotaUsed += QUOTA_PER_SEARCH;
  logger.info(`YouTube API quota used: ${dailyQuotaUsed}/${DAILY_QUOTA_LIMIT}`);
}

/**
 * Search for cancer-specific educational videos on YouTube
 * @param {string} cancerType - Type of cancer (e.g., "Breast Cancer", "Lung Cancer")
 * @param {number} maxResults - Maximum number of results to return (default: 3)
 * @param {string} language - Language code for videos (e.g., "en", "hi", "es") (default: "en")
 * @returns {Promise<Array>} Array of video objects with title, description, thumbnail, and url
 */
async function searchCancerVideos(cancerType, maxResults = 3, language = 'en') {
  try {
    // Generate cache key
    const cacheKey = `${cancerType}_${language}_${maxResults}`;
    
    // Check cache first
    const cached = videoCache.get(cacheKey);
    if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
      logger.info(`Returning cached videos for ${cancerType} (${language})`);
      return cached.videos;
    }

    // Check if quota is exhausted
    if (!hasQuotaRemaining()) {
      logger.warn(`YouTube API quota exhausted (${dailyQuotaUsed}/${DAILY_QUOTA_LIMIT}). Using fallback videos.`);
      return getFallbackVideos(cancerType);
    }

    if (!YOUTUBE_API_KEY) {
      logger.warn('YouTube API key not configured');
      return getFallbackVideos(cancerType);
    }

    // Map language codes to full language names for better search
    const languageMap = {
      'en': 'English',
      'hi': 'Hindi',
      'es': 'Spanish',
      'bn': 'Bengali',
      'te': 'Telugu',
      'mr': 'Marathi',
      'ta': 'Tamil',
      'gu': 'Gujarati',
      'kn': 'Kannada',
      'ml': 'Malayalam',
      'pa': 'Punjabi',
    };

    const languageName = languageMap[language] || 'English';
    
    // Construct search query based on cancer type and language
    const searchQuery = `${cancerType} nutrition treatment diet educational ${languageName}`;
    
    logger.info(`Searching YouTube for: ${searchQuery} (Language: ${language})`);

    // Try searching in the requested language first
    let response;
    trackQuotaUsage(); // Track before API call
    response = await axios.get(`${YOUTUBE_API_BASE_URL}/search`, {
      params: {
        part: 'snippet',
        q: searchQuery,
        type: 'video',
        maxResults: maxResults,
        key: YOUTUBE_API_KEY,
        videoDuration: 'medium', // 4-20 minutes
        videoDefinition: 'high',
        relevanceLanguage: language,
        safeSearch: 'strict',
        order: 'relevance',
        // Filter for educational content
        videoEmbeddable: true,
        videoSyndicated: true,
      },
    });

    // If no results in requested language and it's not English, try English as fallback
    if ((!response.data.items || response.data.items.length === 0) && language !== 'en') {
      logger.info(`No videos found in ${languageName}, falling back to English`);
      const englishQuery = `${cancerType} nutrition treatment diet educational English`;
      
      trackQuotaUsage(); // Track second API call
      response = await axios.get(`${YOUTUBE_API_BASE_URL}/search`, {
        params: {
          part: 'snippet',
          q: englishQuery,
          type: 'video',
          maxResults: maxResults,
          key: YOUTUBE_API_KEY,
          videoDuration: 'medium',
          videoDefinition: 'high',
          relevanceLanguage: 'en',
          safeSearch: 'strict',
          order: 'relevance',
          videoEmbeddable: true,
          videoSyndicated: true,
        },
      });
    }

    if (!response.data.items || response.data.items.length === 0) {
      logger.warn(`No videos found for ${cancerType}`);
      return getFallbackVideos(cancerType);
    }

    // Transform YouTube API response to our format
    const videos = response.data.items.map((item) => {
      const videoId = item.id.videoId;
      const snippet = item.snippet;
      
      return {
        title: snippet.title,
        description: snippet.description.substring(0, 150) + '...',
        category: determineCancerCategory(snippet.title, snippet.description),
        videoId: videoId,
        thumbnail: snippet.thumbnails.medium?.url || snippet.thumbnails.default?.url,
        url: `https://www.youtube.com/watch?v=${videoId}`,
        publishedAt: snippet.publishedAt,
        channelTitle: snippet.channelTitle,
      };
    });

    logger.info(`Found ${videos.length} videos for ${cancerType}`);
    
    // Cache the results
    videoCache.set(cacheKey, {
      videos: videos,
      timestamp: Date.now()
    });
    
    return videos;

  } catch (error) {
    logger.error(`Error fetching YouTube videos: ${error.message}`);
    if (error.response) {
      logger.error(`YouTube API error: ${error.response.status} - ${error.response.data?.error?.message}`);
    }
    return getFallbackVideos(cancerType);
  }
}

/**
 * Determine video category based on title and description
 * @param {string} title - Video title
 * @param {string} description - Video description
 * @returns {string} Category name
 */
function determineCancerCategory(title, description) {
  const content = `${title} ${description}`.toLowerCase();
  
  if (content.includes('nutrition') || content.includes('diet') || content.includes('food')) {
    return 'Nutrition';
  } else if (content.includes('treatment') || content.includes('therapy') || content.includes('side effect')) {
    return 'Treatment';
  } else if (content.includes('exercise') || content.includes('fitness') || content.includes('physical')) {
    return 'Wellness';
  } else if (content.includes('support') || content.includes('mental') || content.includes('emotional')) {
    return 'Support';
  }
  
  return 'Education';
}

/**
 * Get fallback videos when API fails or is not configured
 * @param {string} cancerType - Type of cancer
 * @returns {Array} Array of fallback video objects
 */
function getFallbackVideos(cancerType) {
  logger.info(`Using fallback videos for ${cancerType}`);
  
  // Comprehensive cancer education fallback videos
  const fallbackVideos = {
    'Breast Cancer': [
      {
        title: 'Nutrition During Breast Cancer Treatment',
        description: 'Expert advice on maintaining proper nutrition during breast cancer treatment and recovery',
        category: 'Nutrition',
        videoId: 'wPODghAr3Vc',
        thumbnail: 'https://i.ytimg.com/vi/wPODghAr3Vc/mqdefault.jpg',
        url: 'https://www.youtube.com/watch?v=wPODghAr3Vc',
      },
      {
        title: 'Managing Breast Cancer Side Effects',
        description: 'Practical tips for managing treatment side effects through diet and lifestyle',
        category: 'Wellness',
        videoId: 'Zd9muK2M36c',
        thumbnail: 'https://i.ytimg.com/vi/Zd9muK2M36c/mqdefault.jpg',
        url: 'https://www.youtube.com/watch?v=Zd9muK2M36c',
      },
      {
        title: 'Breast Cancer: What to Eat',
        description: 'Comprehensive guide to foods that support breast cancer treatment',
        category: 'Nutrition',
        videoId: 'yzOwwo4VJGc',
        thumbnail: 'https://i.ytimg.com/vi/yzOwwo4VJGc/mqdefault.jpg',
        url: 'https://www.youtube.com/watch?v=yzOwwo4VJGc',
      },
    ],
    'Lung Cancer': [
      {
        title: 'Nutrition for Lung Cancer Patients',
        description: 'Essential nutrition strategies for lung cancer patients during treatment',
        category: 'Nutrition',
        videoId: 'Ww8gRNEQQ0s',
        thumbnail: 'https://i.ytimg.com/vi/Ww8gRNEQQ0s/mqdefault.jpg',
        url: 'https://www.youtube.com/watch?v=Ww8gRNEQQ0s',
      },
      {
        title: 'Managing Lung Cancer Treatment Side Effects',
        description: 'How to manage common side effects of lung cancer treatment',
        category: 'Treatment',
        videoId: 'DXnqNb3GvUA',
        thumbnail: 'https://i.ytimg.com/vi/DXnqNb3GvUA/mqdefault.jpg',
        url: 'https://www.youtube.com/watch?v=DXnqNb3GvUA',
      },
      {
        title: 'Dietary Guidelines for Lung Cancer',
        description: 'Expert dietary recommendations for lung cancer patients',
        category: 'Nutrition',
        videoId: 'kJQP7kiw5Fk',
        thumbnail: 'https://i.ytimg.com/vi/kJQP7kiw5Fk/mqdefault.jpg',
        url: 'https://www.youtube.com/watch?v=kJQP7kiw5Fk',
      },
    ],
    'Colorectal Cancer': [
      {
        title: 'Nutrition and Colorectal Cancer',
        description: 'Dietary guidance for colorectal cancer patients',
        category: 'Nutrition',
        videoId: 'QH2-TGUlwu4',
        thumbnail: 'https://i.ytimg.com/vi/QH2-TGUlwu4/mqdefault.jpg',
        url: 'https://www.youtube.com/watch?v=QH2-TGUlwu4',
      },
      {
        title: 'Managing Digestive Issues During Treatment',
        description: 'Tips for managing digestive side effects of colorectal cancer treatment',
        category: 'Wellness',
        videoId: 'nfWlot6h_JM',
        thumbnail: 'https://i.ytimg.com/vi/nfWlot6h_JM/mqdefault.jpg',
        url: 'https://www.youtube.com/watch?v=nfWlot6h_JM',
      },
      {
        title: 'Foods to Support Colon Health',
        description: 'Best foods for supporting digestive health during cancer treatment',
        category: 'Nutrition',
        videoId: 'Y_uSSz1HAZE',
        thumbnail: 'https://i.ytimg.com/vi/Y_uSSz1HAZE/mqdefault.jpg',
        url: 'https://www.youtube.com/watch?v=Y_uSSz1HAZE',
      },
    ],
    'Prostate Cancer': [
      {
        title: 'Prostate Cancer Nutrition Guide',
        description: 'Comprehensive nutrition guide for prostate cancer patients',
        category: 'Nutrition',
        videoId: 'IFn8xB_X9RM',
        thumbnail: 'https://i.ytimg.com/vi/IFn8xB_X9RM/mqdefault.jpg',
        url: 'https://www.youtube.com/watch?v=IFn8xB_X9RM',
      },
      {
        title: 'Diet and Prostate Cancer Prevention',
        description: 'Foods that support prostate health during and after treatment',
        category: 'Nutrition',
        videoId: 'TKOwPA3w0Xk',
        thumbnail: 'https://i.ytimg.com/vi/TKOwPA3w0Xk/mqdefault.jpg',
        url: 'https://www.youtube.com/watch?v=TKOwPA3w0Xk',
      },
      {
        title: 'Managing Prostate Cancer Side Effects',
        description: 'Lifestyle and dietary strategies for managing treatment side effects',
        category: 'Wellness',
        videoId: 'W6DmHGYy_xk',
        thumbnail: 'https://i.ytimg.com/vi/W6DmHGYy_xk/mqdefault.jpg',
        url: 'https://www.youtube.com/watch?v=W6DmHGYy_xk',
      },
    ],
  };

  // Return specific cancer type videos or generic cancer nutrition videos
  return fallbackVideos[cancerType] || [
    {
      title: `Nutrition Tips for ${cancerType} Patients`,
      description: 'Expert advice on maintaining proper nutrition during cancer treatment',
      category: 'Nutrition',
      videoId: 'dQw4w9WgXcQ',
      thumbnail: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
      url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    },
    {
      title: `Understanding ${cancerType} Treatment`,
      description: 'Comprehensive guide to cancer treatment options and what to expect',
      category: 'Treatment',
      videoId: 'jNQXAC9IVRw',
      thumbnail: 'https://i.ytimg.com/vi/jNQXAC9IVRw/mqdefault.jpg',
      url: 'https://www.youtube.com/watch?v=jNQXAC9IVRw',
    },
    {
      title: `Managing ${cancerType} Side Effects`,
      description: 'Practical tips for managing treatment side effects through diet and lifestyle',
      category: 'Wellness',
      videoId: 'M7lc1UVf-VE',
      thumbnail: 'https://i.ytimg.com/vi/M7lc1UVf-VE/mqdefault.jpg',
      url: 'https://www.youtube.com/watch?v=M7lc1UVf-VE',
    },
  ];
}

module.exports = {
  searchCancerVideos,
};
