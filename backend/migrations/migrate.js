const { MongoClient } = require('mongodb');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

async function migrate() {
  const client = await MongoClient.connect(process.env.MONGODB_URI);
  const db = client.db();

  try {
    // Get all migration files
    const migrationsDir = path.join(__dirname);
    const migrationFiles = fs.readdirSync(migrationsDir)
      .filter(file => file.endsWith('.js') && file !== 'migrate.js')
      .sort();

    // Create migrations collection if it doesn't exist
    if (!await db.listCollections({ name: 'migrations' }).hasNext()) {
      await db.createCollection('migrations');
    }

    // Get executed migrations
    const executedMigrations = await db.collection('migrations')
      .find()
      .map(doc => doc.fileName)
      .toArray();

    // Execute new migrations
    for (const file of migrationFiles) {
      if (!executedMigrations.includes(file)) {
        console.log(`Executing migration: ${file}`);
        const migration = require(path.join(migrationsDir, file));
        
        await migration.up(db);
        
        await db.collection('migrations').insertOne({
          fileName: file,
          executedAt: new Date()
        });
        
        console.log(`Completed migration: ${file}`);
      }
    }

    console.log('All migrations completed successfully');
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  } finally {
    await client.close();
  }
}

migrate();