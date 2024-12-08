const mongoose = require('mongoose');

module.exports = {
  async up(db) {
    // Create indexes for Event collection
    await db.collection('events').createIndexes([
      { key: { title: 'text', description: 'text', 'location.name': 'text' } },
      { key: { 'location.coordinates': '2dsphere' } },
      { key: { startDateTime: 1 } },
      { key: { tags: 1 } },
      { key: { createdBy: 1 } }
    ]);

    // Create unique index for Tag collection
    await db.collection('tags').createIndex(
      { name: 1 },
      { unique: true }
    );

    // Create indexes for User collection
    await db.collection('users').createIndexes([
      { key: { email: 1 }, unique: true },
      { key: { username: 1 }, unique: true }
    ]);
  },

  async down(db) {
    // Drop indexes
    await db.collection('events').dropIndexes();
    await db.collection('tags').dropIndexes();
    await db.collection('users').dropIndexes();
  }
};