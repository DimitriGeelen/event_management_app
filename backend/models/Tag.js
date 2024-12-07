import mongoose from 'mongoose';

const tagSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  color: {
    type: String,
    required: true,
    default: '#000000'
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

export const Tag = mongoose.model('Tag', tagSchema);