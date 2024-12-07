import React, { useState, useEffect } from 'react';
import { Plus, Edit2, Trash2, Save, X } from 'lucide-react';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { useTag } from '../context/TagContext';
import { useNotification } from '../context/NotificationContext';

const TagManagement = () => {
  const { tags, loading, error: tagError, createTag, updateTag, deleteTag, fetchTags } = useTag();
  const { addNotification } = useNotification();
  const [editingTag, setEditingTag] = useState(null);
  const [newTag, setNewTag] = useState({ name: '', color: '#000000' });
  const [error, setError] = useState('');

  useEffect(() => {
    fetchTags();
  }, [fetchTags]);

  const handleAddTag = async () => {
    try {
      if (!newTag.name.trim()) {
        setError('Tag name is required');
        return;
      }

      await createTag(newTag);
      setNewTag({ name: '', color: '#000000' });
      setError('');
      addNotification({
        type: 'success',
        message: 'Tag created successfully'
      });
    } catch (err) {
      setError(err.message);
    }
  };

  const handleEdit = (tag) => {
    setEditingTag({ ...tag });
  };

  const handleSaveEdit = async () => {
    try {
      if (!editingTag.name.trim()) {
        setError('Tag name is required');
        return;
      }

      await updateTag(editingTag.id, editingTag);
      setEditingTag(null);
      setError('');
      addNotification({
        type: 'success',
        message: 'Tag updated successfully'
      });
    } catch (err) {
      setError(err.message);
    }
  };

  const handleDelete = async (tagId) => {
    try {
      await deleteTag(tagId);
      addNotification({
        type: 'success',
        message: 'Tag deleted successfully'
      });
    } catch (err) {
      setError(err.message);
    }
  };

  if (loading) {
    return <div>Loading...</div>;
  }

  return (
    <div className="max-w-4xl mx-auto p-6">
      <div className="bg-white rounded-lg shadow-md p-6">
        <h2 className="text-2xl font-bold mb-6">Tag Management</h2>

        {(error || tagError) && (
          <Alert className="mb-4" variant="destructive">
            <AlertDescription>{error || tagError}</AlertDescription>
          </Alert>
        )}

        {/* Add New Tag */}
        <div className="mb-8">
          <h3 className="text-lg font-medium mb-4">Add New Tag</h3>
          <div className="flex gap-4">
            <input
              type="text"
              placeholder="Tag name"
              className="flex-1 p-2 border rounded-md"
              value={newTag.name}
              onChange={(e) => setNewTag(prev => ({
                ...prev,
                name: e.target.value
              }))}
            />
            <input
              type="color"
              className="w-20 p-1 border rounded-md"
              value={newTag.color}
              onChange={(e) => setNewTag(prev => ({
                ...prev,
                color: e.target.value
              }))}
            />
            <button
              onClick={handleAddTag}
              className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 flex items-center gap-2"
            >
              <Plus className="w-4 h-4" />
              Add Tag
            </button>
          </div>
        </div>

        {/* Tag List */}
        <div>
          <h3 className="text-lg font-medium mb-4">Existing Tags</h3>
          <div className="space-y-4">
            {tags.map(tag => (
              <div
                key={tag.id}
                className="flex items-center justify-between p-4 border rounded-md"
              >
                {editingTag?.id === tag.id ? (
                  <>
                    <div className="flex gap-4 flex-1">
                      <input
                        type="text"
                        className="flex-1 p-2 border rounded-md"
                        value={editingTag.name}
                        onChange={(e) => setEditingTag(prev => ({
                          ...prev,
                          name: e.target.value
                        }))}
                      />
                      <input
                        type="color"
                        className="w-20 p-1 border rounded-md"
                        value={editingTag.color}
                        onChange={(e) => setEditingTag(prev => ({
                          ...prev,
                          color: e.target.value
                        }))}
                      />
                    </div>
                    <div className="flex gap-2 ml-4">
                      <button
                        onClick={handleSaveEdit}
                        className="p-2 text-green-600 hover:bg-green-50 rounded-md"
                      >
                        <Save className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => setEditingTag(null)}
                        className="p-2 text-gray-600 hover:bg-gray-50 rounded-md"
                      >
                        <X className="w-4 h-4" />
                      </button>
                    </div>
                  </>
                ) : (
                  <>
                    <div className="flex items-center gap-4">
                      <div
                        className="w-6 h-6 rounded-full"
                        style={{ backgroundColor: tag.color }}
                      />
                      <span className="font-medium">{tag.name}</span>
                      <span className="text-sm text-gray-500">
                        {tag.eventCount} events
                      </span>
                    </div>
                    <div className="flex gap-2">
                      <button
                        onClick={() => handleEdit(tag)}
                        className="p-2 text-blue-600 hover:bg-blue-50 rounded-md"
                      >
                        <Edit2 className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => handleDelete(tag.id)}
                        className="p-2 text-red-600 hover:bg-red-50 rounded-md"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </>
                )}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default TagManagement;