import React, { useState, useCallback } from 'react';
import { Calendar, MapPin, Tag, Upload } from 'lucide-react';
import { Alert, AlertDescription } from '@/components/ui/alert';

const EventForm = () => {
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    location: {
      postalCode: '',
      streetName: '',
      streetNumber: '',
      locationName: '',
      coordinates: { lat: null, lng: null }
    },
    startDateTime: '',
    endDateTime: '',
    tags: [],
    files: []
  });
  
  const [suggestions, setSuggestions] = useState([]);
  const [error, setError] = useState('');
  
  const handleLocationSearch = useCallback((searchText) => {
    // Simulated location suggestions
    const mockSuggestions = [
      { id: 1, name: "Central Park", address: "New York, NY" },
      { id: 2, name: "Times Square", address: "Manhattan, NY" }
    ];
    setSuggestions(mockSuggestions);
  }, []);

  const handleFileUpload = (event) => {
    const files = Array.from(event.target.files);
    const validFiles = files.filter(file => 
      file.type.startsWith('image/') || file.type === 'application/pdf'
    );
    
    if (validFiles.length !== files.length) {
      setError('Only images and PDF files are allowed');
      return;
    }
    
    setFormData(prev => ({
      ...prev,
      files: [...prev.files, ...validFiles]
    }));
    setError('');
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    // Form validation logic here
    // API call to create event
  };

  return (
    <div className="max-w-2xl mx-auto p-6 bg-white rounded-lg shadow-md">
      <h2 className="text-2xl font-bold mb-6">Create New Event</h2>
      
      {error && (
        <Alert className="mb-4" variant="destructive">
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}
      
      <form onSubmit={handleSubmit} className="space-y-6">
        <div>
          <label className="block text-sm font-medium mb-2">
            Event Title
          </label>
          <input
            type="text"
            className="w-full p-2 border rounded-md"
            value={formData.title}
            onChange={(e) => setFormData({...formData, title: e.target.value})}
            required
          />
        </div>

        <div>
          <label className="block text-sm font-medium mb-2">
            Description
          </label>
          <textarea
            className="w-full p-2 border rounded-md h-24"
            value={formData.description}
            onChange={(e) => setFormData({...formData, description: e.target.value})}
            required
          />
        </div>

        <div className="space-y-4">
          <div className="flex items-center gap-2">
            <MapPin className="w-5 h-5" />
            <span className="font-medium">Location Details</span>
          </div>
          
          <div className="grid grid-cols-2 gap-4">
            <input
              type="text"
              placeholder="Postal Code"
              className="p-2 border rounded-md"
              value={formData.location.postalCode}
              onChange={(e) => setFormData({
                ...formData,
                location: {...formData.location, postalCode: e.target.value}
              })}
              required
            />
            <input
              type="text"
              placeholder="Street Name"
              className="p-2 border rounded-md"
              value={formData.location.streetName}
              onChange={(e) => setFormData({
                ...formData,
                location: {...formData.location, streetName: e.target.value}
              })}
              required
            />
          </div>
          
          <div className="grid grid-cols-2 gap-4">
            <input
              type="text"
              placeholder="Street Number"
              className="p-2 border rounded-md"
              value={formData.location.streetNumber}
              onChange={(e) => setFormData({
                ...formData,
                location: {...formData.location, streetNumber: e.target.value}
              })}
              required
            />
            <input
              type="text"
              placeholder="Location Name"
              className="p-2 border rounded-md"
              value={formData.location.locationName}
              onChange={(e) => {
                setFormData({
                  ...formData,
                  location: {...formData.location, locationName: e.target.value}
                });
                handleLocationSearch(e.target.value);
              }}
              required
            />
          </div>
          
          {suggestions.length > 0 && (
            <ul className="mt-2 border rounded-md divide-y">
              {suggestions.map(suggestion => (
                <li
                  key={suggestion.id}
                  className="p-2 hover:bg-gray-50 cursor-pointer"
                  onClick={() => {
                    setFormData({
                      ...formData,
                      location: {
                        ...formData.location,
                        locationName: suggestion.name
                      }
                    });
                    setSuggestions([]);
                  }}
                >
                  {suggestion.name} - {suggestion.address}
                </li>
              ))}
            </ul>
          )}
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <div className="flex items-center gap-2 mb-2">
              <Calendar className="w-5 h-5" />
              <span className="font-medium">Start Date & Time</span>
            </div>
            <input
              type="datetime-local"
              className="w-full p-2 border rounded-md"
              value={formData.startDateTime}
              onChange={(e) => setFormData({...formData, startDateTime: e.target.value})}
              required
            />
          </div>
          
          <div>
            <div className="flex items-center gap-2 mb-2">
              <Calendar className="w-5 h-5" />
              <span className="font-medium">End Date & Time</span>
            </div>
            <input
              type="datetime-local"
              className="w-full p-2 border rounded-md"
              value={formData.endDateTime}
              onChange={(e) => setFormData({...formData, endDateTime: e.target.value})}
              required
            />
          </div>
        </div>

        <div>
          <div className="flex items-center gap-2 mb-2">
            <Tag className="w-5 h-5" />
            <span className="font-medium">Tags</span>
          </div>
          <select
            multiple
            className="w-full p-2 border rounded-md h-24"
            value={formData.tags}
            onChange={(e) => setFormData({
              ...formData,
              tags: Array.from(e.target.selectedOptions, option => option.value)
            })}
          >
            <option value="music">Music</option>
            <option value="sports">Sports</option>
            <option value="art">Art</option>
            <option value="technology">Technology</option>
            <option value="food">Food</option>
          </select>
        </div>

        <div>
          <div className="flex items-center gap-2 mb-2">
            <Upload className="w-5 h-5" />
            <span className="font-medium">Upload Files</span>
          </div>
          <input
            type="file"
            multiple
            accept="image/*,.pdf"
            className="w-full p-2 border rounded-md"
            onChange={handleFileUpload}
          />
          <p className="text-sm text-gray-500 mt-1">
            Accepted formats: Images and PDF files
          </p>
        </div>

        <div className="flex justify-end gap-4">
          <button
            type="button"
            className="px-4 py-2 border rounded-md hover:bg-gray-50"
          >
            Cancel
          </button>
          <button
            type="submit"
            className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
          >
            Create Event
          </button>
        </div>
      </form>
    </div>
  );
};

export default EventForm;