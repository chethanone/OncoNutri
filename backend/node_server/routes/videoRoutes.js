const express = require('express');
const router = express.Router();
const { searchCancerVideos } = require('../utils/youtubeService');
const logger = require('../utils/logger');

/**
 * GET /api/videos/:cancerType
 * Fetch educational videos for a specific cancer type
 */
router.get('/:cancerType', async (req, res) => {
  try {
    const { cancerType } = req.params;
    const maxResults = parseInt(req.query.limit) || 3;
    const language = req.query.language || 'en';

    logger.info(`Fetching videos for cancer type: ${cancerType}, language: ${language}`);

    // Validate cancer type
    if (!cancerType || cancerType.trim() === '') {
      return res.status(400).json({
        success: false,
        message: 'Cancer type is required',
      });
    }

    // Fetch videos from YouTube API with language preference
    const videos = await searchCancerVideos(cancerType, maxResults, language);

    res.json({
      success: true,
      cancerType: cancerType,
      count: videos.length,
      videos: videos,
    });

  } catch (error) {
    logger.error(`Error in video route: ${error.message}`);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch videos',
      error: error.message,
    });
  }
});

module.exports = router;
