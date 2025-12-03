const express = require('express');
const router = express.Router();

// Get patient profile
router.get('/:id', (req, res) => {
    res.json({ 
        success: true,
        patient: { id: req.params.id }
    });
});

module.exports = router;
