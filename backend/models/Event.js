import mongoose from 'mongoose';

const eventSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    required: true
  },
  location: {
    name: {
      type: String,
      required: true
    },
    streetName: {
      type: String,
      required: true
    },
    streetNumber: {
      type: String,
      required: true
    },
    postalCode: {
      type: String,
      required: true
    },
    coordinates: {
      lat: {
        type: Number,
        required: true
      },
      lng: {
        type: Number,
        required: true
      }
    }
  },
  startDateTime: {
    type: Date,
    required: true
  },
  endDateTime: {
    type: Date,
    required: true
  },
  tags: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Tag'
  }],
  files: [{
    filename: String,
    originalName: String,
    path: String,
    mimetype: String
  }],
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Add text index for search
eventSchema.index({
  title: 'text',
  description: 'text',
  'location.name': 'text'
});

// Update timestamps on save
eventSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

export const Event = mongoose.model('Event', eventSchema);