import express from 'express';
import { Tag } from '../models/Tag.js';
import { Event } from '../models/Event.js';
import { auth } from '../middleware/auth.js';
import { isAdmin } from '../middleware/isAdmin.js';

const router = express.Router();

// Get all tags
router.get('/', async (req, res) => {
  try {
    const tags = await Tag.find();
    
    // Get event count for each tag
    const tagsWithCount = await Promise.all(tags.map(async tag => {
      const count = await Event.countDocuments({ tags: tag._id });
      return {
        ...tag.toObject(),
        eventCount: count
      };
    }));

    res.json(tagsWithCount);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create tag (admin only)
router.post('/', [auth, isAdmin], async (req, res) => {
  try {
    const { name, color } = req.body;

    const tagExists = await Tag.findOne({ name: name.toLowerCase() });
    if (tagExists) {
      return res.status(400).json({ error: 'Tag already exists' });
    }

    const tag = new Tag({
      name: name.toLowerCase(),
      color
    });

    await tag.save();
    res.status(201).json(tag);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Update tag (admin only)
router.put('/:id', [auth, isAdmin], async (req, res) => {
  try {
    const { name, color } = req.body;

    if (name) {
      const tagExists = await Tag.findOne({
        name: name.toLowerCase(),
        _id: { $ne: req.params.id }
      });
      
      if (tagExists) {
        return res.status(400).json({ error: 'Tag name already exists' });
      }
    }

    const tag = await Tag.findByIdAndUpdate(
      req.params.id,
      { 
        ...(name && { name: name.toLowerCase() }),
        ...(color && { color })
      },
      { new: true }
    );

    if (!tag) {
      return res.status(404).json({ error: 'Tag not found' });
    }

    const eventCount = await Event.countDocuments({ tags: tag._id });
    res.json({ ...tag.toObject(), eventCount });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Delete tag (admin only)
router.delete('/:id', [auth, isAdmin], async (req, res) => {
  try {
    const eventCount = await Event.countDocuments({ tags: req.params.id });
    if (eventCount > 0) {
      return res.status(400).json({ 
        error: `Cannot delete tag as it is used by ${eventCount} events`
      });
    }

    const tag = await Tag.findByIdAndDelete(req.params.id);
    if (!tag) {
      return res.status(404).json({ error: 'Tag not found' });
    }

    res.json({ message: 'Tag deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

export default router;