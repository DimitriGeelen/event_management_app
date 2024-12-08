module.exports = {
  async up(db) {
    // Add status field to all existing events
    await db.collection('events').updateMany(
      {},
      {
        $set: { status: 'active' }
      }
    );

    // Create index for status field
    await db.collection('events').createIndex({ status: 1 });
  },

  async down(db) {
    // Remove status field from all events
    await db.collection('events').updateMany(
      {},
      {
        $unset: { status: '' }
      }
    );

    // Drop status index
    await db.collection('events').dropIndex('status_1');
  }
};