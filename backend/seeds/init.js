const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
require('dotenv').config();

// Import models
require('../models/User');
require('../models/Tag');
require('../models/Event');

const User = mongoose.model('User');
const Tag = mongoose.model('Tag');
const Event = mongoose.model('Event');

const initialTags = [
  { name: 'music', color: '#3B82F6' },
  { name: 'sports', color: '#10B981' },
  { name: 'art', color: '#EC4899' },
  { name: 'technology', color: '#6366F1' },
  { name: 'food', color: '#F59E0B' }
];

const initialUsers = [
  {
    username: 'admin',
    email: 'admin@example.com',
    password: 'admin123',
    role: 'admin'
  },
  {
    username: 'user',
    email: 'user@example.com',
    password: 'user123',
    role: 'user'
  }
];

const generateEvents = (users, tags) => {
  const events = [];
  const locations = [
    {
      name: 'Central Park',
      streetName: 'Central Park West',
      streetNumber: '1',
      postalCode: '10023',
      coordinates: { lat: 40.785091, lng: -73.968285 }
    },
    {
      name: 'Times Square',
      streetName: 'Broadway',
      streetNumber: '1475',
      postalCode: '10036',
      coordinates: { lat: 40.758896, lng: -73.985130 }
    }
  ];

  for (let i = 0; i < 10; i++) {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() + Math.floor(Math.random() * 30));
    
    const endDate = new Date(startDate);
    endDate.setHours(endDate.getHours() + Math.floor(Math.random() * 8));

    events.push({
      title: `Test Event ${i + 1}`,
      description: `Description for test event ${i + 1}`,
      location: locations[Math.floor(Math.random() * locations.length)],
      startDateTime: startDate,
      endDateTime: endDate,
      tags: [tags[Math.floor(Math.random() * tags.length)]._id],
      createdBy: users[Math.floor(Math.random() * users.length)]._id,
      status: 'active'
    });
  }

  return events;
};

async function seed() {
  try {
    // Connect to database
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to database');

    // Clear existing data
    await Promise.all([
      User.deleteMany({}),
      Tag.deleteMany({}),
      Event.deleteMany({})
    ]);
    console.log('Cleared existing data');

    // Create users
    const hashedUsers = await Promise.all(
      initialUsers.map(async user => {
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(user.password, salt);
        return {
          ...user,
          password: hashedPassword
        };
      })
    );

    const users = await User.create(hashedUsers);
    console.log('Created users');

    // Create tags
    const tags = await Tag.create(initialTags);
    console.log('Created tags');

    // Create events
    const events = generateEvents(users, tags);
    await Event.create(events);
    console.log('Created events');

    console.log('Seeding completed successfully');
    process.exit(0);
  } catch (error) {
    console.error('Seeding failed:', error);
    process.exit(1);
  }
}

seed();