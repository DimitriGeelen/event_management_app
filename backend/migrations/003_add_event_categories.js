module.exports = {
  async up(db) {
    // Create categories collection with initial data
    await db.createCollection('categories');
    await db.collection('categories').insertMany([
      { name: 'Music', slug: 'music', color: '#3B82F6' },
      { name: 'Sports', slug: 'sports', color: '#10B981' },
      { name: 'Art', slug: 'art', color: '#EC4899' },
      { name: 'Technology', slug: 'technology', color: '#6366F1' },
      { name: 'Food', slug: 'food', color: '#F59E0B' }
    ]);

    // Add categories field to events
    await db.collection('events').updateMany(
      {},
      {
        $set: { categories: [] }
      }
    );

    // Create index for categories
    await db.collection('events').createIndex({ categories: 1 });
  },

  async down(db) {
    // Drop categories collection
    await db.collection('categories').drop();

    // Remove categories field from events
    await db.collection('events').updateMany(
      {},
      {
        $unset: { categories: '' }
      }
    );

    // Drop categories index
    await db.collection('events').dropIndex('categories_1');
  }
};